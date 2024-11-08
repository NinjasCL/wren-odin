# Wren in Odin

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

 - **Wren is small.** The VM implementation is under 4,000 semicolons.
    You can skim the whole thing in an afternoon. It's *small*, but not
    *dense*. It is readable and lovingly-commented.

 - **Wren is fast.** A fast single-pass compiler to tight bytecode, and a
    compact object representation help Wren compete with other dynamic
    languages.

 - **Wren is class-based.** There are lots of scripting languages out there,
    but many have unusual or non-existent object models. Wren places
    classes front and center.

 - **Wren is concurrent.** Lightweight fibers are core to the execution
    model and let you organize your program into an army of communicating
    coroutines.

 - **Wren is a scripting language.** Wren is intended for embedding in
    applications. It has no dependencies, a small standard library,
    and an easy-to-use C API. It compiles cleanly as C99, C++98
    or anything later.

## Links

- Syntax: http://wren.io/syntax.html
- Github: https://github.com/wren-lang/wren/tree/main/src
- Getting Started: http://wren.io/getting-started.html

## Usage

See more complete examples at `example.odin` and `tests/wren_tests.odin`

```odin
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

## License

- BSD-3


## Credits

<p>
  Made with <i class="fa fa-heart">&#9829;</i> by
  <a href="https://ninjas.cl">
    Ninjas.cl
  </a>.
</p>
