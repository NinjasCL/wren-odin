package wren_odin_example

// You can check the tests/wren_tests.odin file for a more complete list of examples

import "core:fmt"
import "base:runtime"

// We need a named import since 0.4 is not a valid package name
import wren "./0.4"

// The callback Wren uses to display text when `System.print()` or the other
// related functions are called.
//
// If this is `NULL`, Wren discards any printed text.
// context is required to use Odin functions
wren_log_message_callback :: proc "c" (vm: ^wren.VM, message: cstring) {
	context = (^runtime.Context)(wren.GetUserData(vm))^
	fmt.println(message)
}

main :: proc() {
	// Configuration needs to be initialized before creating the VM
  config := wren.Configuration{}
  wren.InitConfiguration(&config)

	// We save the context to it can be reused inside proc "c" procedures
	user_data := context
  config.userData = &user_data

	// Define all the callbacks
  config.writeFn = wren_log_message_callback

	// Creates a new VM and defers it's deletion
  vm := wren.NewVM(&config)
	defer wren.FreeVM(vm)

	// The module name and code to interpret
	module : cstring = "main"
	script : cstring = `System.print("Hellope Odin!. Said the Wren.")`

	// The result can be a compilation error, runtime error or success
	// The callbacks will be called by Wren's lifecycle
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
