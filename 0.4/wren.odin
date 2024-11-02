/** doc-name: wren */
package wren_0_4

/** doc-header

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

- Since: 1.0.0

*/

import _c "core:c"

when ODIN_OS == .Windows do foreign import "lib/windows/wren.lib"
when ODIN_OS == .Linux   do foreign import "lib/linux/wren.a"
when ODIN_OS == .Darwin  do foreign import "lib/macos/wren.a"

wren_h :: 1

VERSION_MAJOR       :: 0
VERSION_MINOR       :: 4
VERSION_RELEASE     :: 0
VERSION_RELEASE_STRING :: "0"

VERSION_NUMBER      :: VERSION_MAJOR * 1000000 + VERSION_MINOR * 1000 + VERSION_RELEASE
VERSION_STRING      :: "0.4"

VERSION             :: "Wren " + VERSION_STRING
RELEASE             :: VERSION + "." + VERSION_RELEASE_STRING
COPYRIGHT           :: RELEASE + "  Copyright (C) Wren.io, Bob Nystrom"
AUTHORS             :: "Made with ❤ by Bob Nystrom and friends."

// Mark for precompiled code ('<esc>Wren')
SIGNATURE :: "\x1bWren"

// Inspired by https://github.com/lumi-c/odin-wren

ReallocateFn :: #type proc "c" (memory: rawptr, newSize: u64, userData: rawptr) -> rawptr

ForeignMethodFn :: #type proc "c" (vm: ^VM)
FinalizerFn :: #type proc "c" (data: rawptr)
ResolveModuleFn :: #type proc "c" (vm: ^VM, importer: cstring, name: cstring) -> cstring
LoadModuleCompleteFn :: #type proc "c" (vm: ^VM, name: cstring, result: LoadModuleResult)
LoadModuleFn :: #type proc "c" (vm: ^VM, name: cstring) -> LoadModuleResult
BindForeignMethodFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring, isStatic: bool, signature: cstring) -> ForeignMethodFn
WriteFn :: #type proc "c" (vm: ^VM, message: cstring)
ErrorType :: ErrorTypeEnum
ErrorFn :: #type proc "c" (vm: ^VM, type: ErrorType, module: cstring, line: _c.int, message: cstring)
ForeignClassMethods :: ForeignClassMethodsStruct
BindForeignClassFn :: #type proc "c" (vm: ^VM, module: cstring, className: cstring) -> ForeignClassMethods
Configuration :: ConfigurationStruct
InterpretResult :: InterpretResultEnum
Type :: WrenTypeEnum

ErrorTypeEnum :: enum i32 {
    WREN_ERROR_COMPILE,
    WREN_ERROR_RUNTIME,
    WREN_ERROR_STACK_TRACE,
}

InterpretResultEnum :: enum i32 {
    WREN_RESULT_SUCCESS,
    WREN_RESULT_COMPILE_ERROR,
    WREN_RESULT_RUNTIME_ERROR,
}

WrenTypeEnum :: enum i32 {
    WREN_TYPE_BOOL,
    WREN_TYPE_NUM,
    WREN_TYPE_FOREIGN,
    WREN_TYPE_LIST,
    WREN_TYPE_MAP,
    WREN_TYPE_NULL,
    WREN_TYPE_STRING,
    WREN_TYPE_UNKNOWN,
}

VM :: struct {
    config: Configuration
}

Handle :: struct {}

LoadModuleResult :: struct {
    source : cstring,
    onComplete : LoadModuleCompleteFn,
    userData : rawptr,
}

ForeignClassMethodsStruct :: struct {
    allocate : ForeignMethodFn,
    finalize : FinalizerFn,
}

ConfigurationStruct :: struct {
    reallocateFn : ReallocateFn,
    resolveModuleFn : ResolveModuleFn,
    loadModuleFn : LoadModuleFn,
    bindForeignMethodFn : BindForeignMethodFn,
    bindForeignClassFn : BindForeignClassFn,
    writeFn : WriteFn,
    errorFn : ErrorFn,
    initialHeapSize : _c.size_t,
    minHeapSize : _c.size_t,
    heapGrowthPercent : _c.int,
    userData : rawptr,
}


@(default_calling_convention="c")
/**
Main container for the Wren API.
- Since: 1.0.0
*/
foreign wren {

    @(link_name="wrenInitConfiguration")
    InitConfiguration :: proc(configuration : ^Configuration) ---

    @(link_name="wrenNewVM")
    NewVM :: proc(configuration : ^Configuration) -> ^VM ---

    @(link_name="wrenFreeVM")
    FreeVM :: proc(vm : ^VM) ---

    @(link_name="wrenCollectGarbage")
    CollectGarbage :: proc(vm : ^VM) ---

    @(link_name="wrenInterpret")
    Interpret :: proc(
        vm : ^VM,
        module : cstring,
        source : cstring,
    ) -> InterpretResult ---

    @(link_name="wrenMakeCallHandle")
    MakeCallHandle :: proc(
        vm : ^VM,
        signature : cstring,
    ) -> ^Handle ---

    @(link_name="wrenCall")
    Call :: proc(
        vm : ^VM,
        method : ^Handle,
    ) -> InterpretResult ---

    @(link_name="wrenReleaseHandle")
    ReleaseHandle :: proc(
        vm : ^VM,
        handle : ^Handle,
    ) ---

    @(link_name="wrenGetSlotCount")
    GetSlotCount :: proc(vm : ^VM) -> _c.int ---

    @(link_name="wrenEnsureSlots")
    EnsureSlots :: proc(
        vm : ^VM,
        numSlots : _c.int,
    ) ---

    @(link_name="wrenGetSlotType")
    GetSlotType :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> Type ---

    @(link_name="wrenGetSlotBool")
    GetSlotBool :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> bool ---

    @(link_name="wrenGetSlotBytes")
    GetSlotBytes :: proc(
        vm : ^VM,
        slot : _c.int,
        length : ^_c.int,
    ) -> cstring ---

    @(link_name="wrenGetSlotDouble")
    GetSlotDouble :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.double ---

    @(link_name="wrenGetSlotForeign")
    GetSlotForeign :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> rawptr ---

    @(link_name="wrenGetSlotString")
    GetSlotString :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> cstring ---

    @(link_name="wrenGetSlotHandle")
    GetSlotHandle :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> ^Handle ---

    @(link_name="wrenSetSlotBool")
    SetSlotBool :: proc(
        vm : ^VM,
        slot : _c.int,
        value : bool,
    ) ---

    @(link_name="wrenSetSlotBytes")
    SetSlotBytes :: proc(
        vm : ^VM,
        slot : _c.int,
        bytes : cstring,
        length : _c.size_t,
    ) ---

    @(link_name="wrenSetSlotDouble")
    SetSlotDouble :: proc(
        vm : ^VM,
        slot : _c.int,
        value : _c.double,
    ) ---

    @(link_name="wrenSetSlotNewForeign")
    SetSlotNewForeign :: proc(
        vm : ^VM,
        slot : _c.int,
        classSlot : _c.int,
        size : _c.size_t,
    ) -> rawptr ---

    @(link_name="wrenSetSlotNewList")
    SetSlotNewList :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotNewMap")
    SetSlotNewMap :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotNull")
    SetSlotNull :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenSetSlotString")
    SetSlotString :: proc(
        vm : ^VM,
        slot : _c.int,
        text : cstring,
    ) ---

    @(link_name="wrenSetSlotHandle")
    SetSlotHandle :: proc(
        vm : ^VM,
        slot : _c.int,
        handle : ^Handle,
    ) ---

    @(link_name="wrenGetListCount")
    GetListCount :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.int ---

    @(link_name="wrenGetListElement")
    GetListElement :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenSetListElement")
    SetListElement :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenInsertInList")
    InsertInList :: proc(
        vm : ^VM,
        listSlot : _c.int,
        index : _c.int,
        elementSlot : _c.int,
    ) ---

    @(link_name="wrenGetMapCount")
    GetMapCount :: proc(
        vm : ^VM,
        slot : _c.int,
    ) -> _c.int ---

    @(link_name="wrenGetMapContainsKey")
    GetMapContainsKey :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
    ) -> bool ---

    @(link_name="wrenGetMapValue")
    GetMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        valueSlot : _c.int,
    ) ---

    @(link_name="wrenSetMapValue")
    SetMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        valueSlot : _c.int,
    ) ---

    @(link_name="wrenRemoveMapValue")
    RemoveMapValue :: proc(
        vm : ^VM,
        mapSlot : _c.int,
        keySlot : _c.int,
        removedValueSlot : _c.int,
    ) ---

    @(link_name="wrenGetVariable")
    GetVariable :: proc(
        vm : ^VM,
        module : cstring,
        name : cstring,
        slot : _c.int,
    ) ---

    @(link_name="wrenHasVariable")
    HasVariable :: proc(
        vm : ^VM,
        module : cstring,
        name : cstring,
    ) -> bool ---

    @(link_name="wrenHasModule")
    HasModule :: proc(
        vm : ^VM,
        module : cstring,
    ) -> bool ---

    @(link_name="wrenAbortFiber")
    AbortFiber :: proc(
        vm : ^VM,
        slot : _c.int,
    ) ---

    @(link_name="wrenGetUserData")
    GetUserData :: proc(vm : ^VM) -> rawptr ---

    @(link_name="wrenSetUserData")
    SetUserData :: proc(
        vm : ^VM,
        userData : rawptr,
    ) ---

}
