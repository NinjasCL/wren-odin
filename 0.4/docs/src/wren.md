<!-- file: wren.odin -->
<!-- documentation automatically generated using domepunk/tools/doc -->

## Wren API Bindings

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


## API

### [foreign wren](https://github.com/ninjascl/wren-odin/blob/main/wren.odin#L136)


Main container for the Wren API.
- Since: 1.0.0
