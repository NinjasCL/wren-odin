/** doc-disable */
package tests

import "core:log"
import "core:testing"
import "core:os"
import "core:fmt"
import "base:runtime"
import _c "core:c"

import wren ".."

// The callback Wren uses to display text when `System.print()` or the other
// related functions are called.
//
// If this is `NULL`, Wren discards any printed text.
wren_log_message_callback :: proc "c" (vm: ^wren.VM, message: cstring) {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(string(message))
}

// The callback Wren uses to report errors.
//
// When an error occurs, this will be called with the module name, line
// number, and an error message. If this is `NULL`, Wren doesn't report any
// errors.
wren_log_error_callback :: proc "c" (vm: ^wren.VM, type: wren.ErrorType, module: cstring, line: _c.int, message: cstring) {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(string(message))
}

// A foreign procedure to test foreign binding to Wren
foreign_procedure_get_name :: proc "c" (vm: ^wren.VM) {
    wren.EnsureSlots(vm, 1)
    wren.SetSlotString(vm, 0, cstring("odin"))
}

// A finalizer function for freeing resources owned by an instance of a foreign
// class. Unlike most foreign methods, finalizers do not have access to the VM
// and should not interact with it since it's in the middle of a garbage
// collection.
foreign_procedure_finalizer :: proc "c" (data: rawptr) {
    context = runtime.default_context()
    defer free(data)
}

// Returns a pointer to a foreign method on [className] in [module] with
// [signature].
// Normally a map in Odin would be implemented to look for method based on module->classname->signature
wren_bind_foreign_method_callback :: proc "c" (vm: ^wren.VM, module: cstring, className: cstring, isStatic: bool, signature: cstring) -> wren.ForeignMethodFn {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(module, className, isStatic, signature)
    return foreign_procedure_get_name
}

// The callback Wren uses to find a foreign class and get its foreign methods.
//
// When a foreign class is declared, this will be called with the class's
// module and name when the class body is executed. It should return the
// foreign functions uses to allocate and (optionally) finalize the bytes
// stored in the foreign object when an instance is created.
// Returns a pair of pointers to the foreign methods used to allocate and
// finalize the data for instances of [className] in resolved [module].
wren_bind_foreign_class_callback :: proc "c" (vm: ^wren.VM, module: cstring, className: cstring) -> wren.ForeignClassMethods {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(module, className)
    result := wren.ForeignClassMethods{}
    result.allocate = foreign_procedure_get_name
    result.finalize = foreign_procedure_finalizer

    return result
}

// The callback Wren uses to resolve a module name.
//
// Some host applications may wish to support "relative" imports, where the
// meaning of an import string depends on the module that contains it. To
// support that without baking any policy into Wren itself, the VM gives the
// host a chance to resolve an import string.
//
// Before an import is loaded, it calls this, passing in the name of the
// module that contains the import and the import string. The host app can
// look at both of those and produce a new "canonical" string that uniquely
// identifies the module. This string is then used as the name of the module
// going forward. It is what is passed to [loadModuleFn], how duplicate
// imports of the same module are detected, and how the module is reported in
// stack traces.
//
// If you leave this function NULL, then the original import string is
// treated as the resolved string.
//
// If an import cannot be resolved by the embedder, it should return NULL and
// Wren will report that as a runtime error.
//
// Wren will take ownership of the string you return and free it for you, so
// it should be allocated using the same allocation function you provide
// above.
// Gives the host a chance to canonicalize the imported module name,
// potentially taking into account the (previously resolved) name of the module
// that contains the import. Typically, this is used to implement relative
// imports.
wren_resolve_module_callback :: proc "c" (vm: ^wren.VM, importer: cstring, name: cstring) -> cstring {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(importer, name)
    return name
}

// Called after loadModuleFn is called for module [name]. The original returned result
// is handed back to you in this callback, so that you can free memory if appropriate.
wren_load_module_did_complete_callback :: proc "c" (vm: ^wren.VM, name: cstring, result: wren.LoadModuleResult) {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(name, result)
}

// The callback Wren uses to load a module.
//
// Since Wren does not talk directly to the file system, it relies on the
// embedder to physically locate and read the source code for a module. The
// first time an import appears, Wren will call this and pass in the name of
// the module being imported. The method will return a result, which contains
// the source code for that module. Memory for the source is owned by the
// host application, and can be freed using the onComplete callback.
//
// This will only be called once for any given module name. Wren caches the
// result internally so subsequent imports of the same module will use the
// previous source and not call this.
//
// If a module with the given name could not be found by the embedder, it
// should return NULL and Wren will report that as a runtime error.
// LoadModuleResult is the result of a loadModuleFn call.
// [source] is the source code for the module, or NULL if the module is not found.
// [onComplete] an optional callback that will be called once Wren is done with the result.
//
// Normally this will use a map to load a module in Odin
wren_load_module_callback :: proc "c" (vm: ^wren.VM, name: cstring) -> wren.LoadModuleResult {
    context = (^runtime.Context)(wren.GetUserData(vm))^
    log.debug(name)
    result := wren.LoadModuleResult{}
    result.source = `
        class Platform {
            static name {"odin"}
        }
    `
    result.onComplete = wren_load_module_did_complete_callback
    result.userData = wren.GetUserData(vm)
    return result
}

@(test)
test_that_vm_can_be_created :: proc(t: ^testing.T) {
    // Configuration and InitConfiguration must be called before anything else
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    config.writeFn = wren_log_message_callback

    vm := wren.NewVM(&config)

    module : cstring = "main"
    script : cstring = `System.print("Hello Wren from Odin!")`

    result := wren.Interpret(vm, module, script)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_SUCCESS) {
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}

@(test)
test_that_vm_can_access_variables :: proc(t: ^testing.T) {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    vm := wren.NewVM(&config)

    module : cstring = "test"
    script : cstring = `
        class Platform {
            static name {"odin"}
        }

        var platform = Platform.name
    `

    result := wren.Interpret(vm, module, script)

    wren.EnsureSlots(vm, 1)
    wren.GetVariable(vm, "test", "platform", 0)
    platform : cstring = wren.GetSlotString(vm, 0)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_SUCCESS) {
        testing.expect_value(t, platform, cstring("odin"))
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}

@(test)
test_that_vm_can_write_to_stdout :: proc(t: ^testing.T) {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    config.writeFn = wren_log_message_callback

    vm := wren.NewVM(&config)

    module : cstring = "test"
    script : cstring = `
        System.print("odin")
    `
    result := wren.Interpret(vm, module, script)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_SUCCESS) {
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}

@(test)
test_that_vm_can_write_to_stderr :: proc(t: ^testing.T) {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    config.errorFn = wren_log_error_callback

    vm := wren.NewVM(&config)

    module : cstring = "test"
    script : cstring = `
        // Bad syntax error trigger
        var out = System.print("odin
    `

    result := wren.Interpret(vm, module, script)

    wren.EnsureSlots(vm, 1)
    wren.GetVariable(vm, "test", "out", 0)
    platform : cstring = wren.GetSlotString(vm, 0)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_COMPILE_ERROR) {
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}

@(test)
test_that_vm_can_access_foreign_methods :: proc(t: ^testing.T) {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    config.errorFn = wren_log_error_callback
    config.bindForeignMethodFn = wren_bind_foreign_method_callback

    vm := wren.NewVM(&config)

    module : cstring = "test"
    script : cstring = `
        class Platform {
           foreign static name
        }

        var platform = Platform.name
    `
    result := wren.Interpret(vm, module, script)

    wren.EnsureSlots(vm, 1)
    wren.GetVariable(vm, "test", "platform", 0)
    platform : cstring = wren.GetSlotString(vm, 0)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_SUCCESS) {
        testing.expect_value(t, platform, cstring("odin"))
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}

@(test)
test_that_vm_can_resolve_imports :: proc(t: ^testing.T) {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    // We need to pass the current context so odin functions will work inside C procedures
    // context = (^runtime.Context)(wren.GetUserData(vm))^
    userData := context
    config.userData = &userData

    config.errorFn = wren_log_error_callback
    config.resolveModuleFn = wren_resolve_module_callback
    config.loadModuleFn = wren_load_module_callback

    vm := wren.NewVM(&config)

    module : cstring = "test"
    script : cstring = `
        import "platform" for Platform
        var name = Platform.name
    `
    result := wren.Interpret(vm, module, script)

    wren.EnsureSlots(vm, 1)
    wren.GetVariable(vm, "test", "name", 0)
    platform : cstring = wren.GetSlotString(vm, 0)

    defer wren.FreeVM(vm)

    if testing.expect_value(t, result, wren.InterpretResult.WREN_RESULT_SUCCESS) {
        testing.expect_value(t, platform, cstring("odin"))
        return
    }

    testing.cleanup(t, proc (raw_handle: rawptr) {
        handle := cast(^os.Handle) raw_handle
        os.close(handle^)
    }, &result)
}
