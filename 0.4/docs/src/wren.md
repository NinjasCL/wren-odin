<!-- file: wren.odin -->
<!-- documentation automatically generated using domepunk/tools/doc -->

# Wren API Bindings

Wren is a small, fast, class-based concurrent scripting language

Think Smalltalk in a Lua-sized package with a dash of Erlang and wrapped up in
a familiar, modern syntax.

```js
System.print("Hello, world!")

class Wren {
  flyTo(city) {
    System.print("Flying to %(city)")
  }
}

var adjectives = Fiber.new {
  ["small", "clean", "fast"].each {|word| Fiber.yield(word) }
}

while (!adjectives.isDone) System.print(adjectives.call())
```

## Usage

See more complete examples at `example.odin` and `tests/wren_tests.odin`

```go
package main

import "core:fmt"

import wren "../vendor/wren/0.4"

main :: proc() {
    config := wren.Configuration{}
    wren.InitConfiguration(&config)

    vm := wren.NewVM(&config)

    module : cstring = "main"
    script : cstring = `System.print("Hello Wren from Odin!")`
    result := wren.Interpret(vm, module, script)

    switch result {
        case .WREN_RESULT_COMPILE_ERROR:
            fmt.println("Compile error")
        case .WREN_RESULT_RUNTIME_ERROR:
            fmt.println("Runtime error")
        case .WREN_RESULT_SUCCESS:
            fmt.println("Success!")
    }
}
```

## API

### [ReallocateFn :: #type proc "c" (memory: rawptr, newSize: u64, userData: rawptr) -> rawptr](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L105)


A generic allocation function that handles all explicit memory management
used by Wren. It's used like so:

- To allocate new memory, [memory] is NULL and [newSize] is the desired
  size. It should return the allocated memory or NULL on failure.

- To attempt to grow an existing allocation, [memory] is the memory, and
  [newSize] is the desired size. It should return [memory] if it was able to
  grow it in place, or a new pointer if it had to move it.

- To shrink memory, [memory] and [newSize] are the same as above but it will
  always return [memory].

- To free memory, [memory] will be the memory to free and [newSize] will be
  zero. It should return NULL.

### [ForeignMethodFn :: #type proc "c" (vm: ^VM)](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L110)


A function callable from Wren code, but implemented in C.

### [FinalizerFn :: #type proc "c" (data: rawptr)](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L118)


A finalizer function for freeing resources owned by an instance of a foreign
class. Unlike most foreign methods, finalizers do not have access to the VM
and should not interact with it since it's in the middle of a garbage
collection.

### [ResolveModuleFn :: #type proc "c" (vm: ^VM, importer: cstring, name: cstring) -> cstring](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L126)


Gives the host a chance to canonicalize the imported module name,
potentially taking into account the (previously resolved) name of the module
that contains the import. Typically, this is used to implement relative
imports.

### [LoadModuleCompleteFn :: #type proc "c" (vm: ^VM, name: cstring, result: LoadModuleResult)](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L132)


Called after loadModuleFn is called for module [name]. The original returned result
is handed back to you in this callback, so that you can free memory if appropriate.

### [LoadModuleFn :: #type proc "c" (vm: ^VM, name: cstring) -> LoadModuleResult](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L137)


Loads and returns the source code for the module [name].

### [BindForeignMethodFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring, isStatic: bool, signature: cstring) -> ForeignMethodFn](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L143)


Returns a pointer to a foreign method on [className] in [module] with
[signature].

### [WriteFn :: #type proc "c" (vm: ^VM, message: cstring)](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L148)


Displays a string of text to the user.

### [ErrorFn :: #type proc "c" (vm: ^VM, type: ErrorType, module: cstring, line: _c.int, message: cstring)](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L166)


Reports an error to the user.

An error detected during compile time is reported by calling this once with
[type] `WREN_ERROR_COMPILE`, the resolved name of the [module] and [line]
where the error occurs, and the compiler's error [message].

A runtime error is reported by calling this once with [type]
`WREN_ERROR_RUNTIME`, no [module] or [line], and the runtime error's
[message]. After that, a series of [type] `WREN_ERROR_STACK_TRACE` calls are
made for each line in the stack trace. Each of those has the resolved
[module] and [line] where the method or function is defined and [message] is
the name of the method or function.

### [BindForeignClassFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring) -> ForeignClassMethods](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L174)


Returns a pair of pointers to the foreign methods used to allocate and
finalize the data for instances of [className] in resolved [module].

### [foreign wren](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L240)


Main container for the Wren API.
- Since: 1.0.0

### [InitConfiguration :: proc(configuration : ^Configuration) ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L247)


Initializes [configuration] with all of its default values.
Call this before setting the particular fields you care about.

### [NewVM :: proc(configuration : ^Configuration) -> ^VM ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L256)


Creates a new Wren virtual machine using the given [configuration]. Wren
will copy the configuration data, so the argument passed to this can be
freed after calling this. If [configuration] is `NULL`, uses a default
configuration.

### [FreeVM :: proc(vm : ^VM) ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L263)


Disposes of all resources is use by [vm], which was previously created by a
call to [wrenNewVM].

### [CollectGarbage :: proc(vm : ^VM) ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L269)


Immediately run the garbage collector to free unused memory.

### [Interpret :: proc(vm : ^VM, module : cstring, source : cstring) -> InterpretResult ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L276)


Runs [source], a string of Wren source code in a new fiber in [vm] in the
context of resolved [module].

### [MakeCallHandle :: proc(vm : ^VM, signature : cstring) -> ^Handle ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L289)


Creates a handle that can be used to invoke a method with [signature] on
using a receiver and arguments that are set up on the stack.

This handle can be used repeatedly to directly invoke that method from C
code using [wrenCall].

When you are done with this handle, it must be released using
[wrenReleaseHandle].

### [Call :: proc(vm : ^VM, method : ^Handle) -> InterpretResult ---](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L303)


Calls [method], using the receiver and arguments previously set up on the stack.

[method] must have been created by a call to [wrenMakeCallHandle]. The
arguments to the method must be already on the stack. The receiver should be
in slot 0 with the remaining arguments following it, in order. It is an
error if the number of arguments provided does not match the method's
signature.

After this returns, you can access the return value from slot 0 on the stack.
