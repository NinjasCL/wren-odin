## [Wren Documentation Generator (_WrenDoc_)](https://github.com/NinjasCL/domepunk/tree/main/tools/docs)

Code structure and organization is a matter of pride for developers.
Clear and consistent code signifies clear and consistent thought.

Even though the compiler lacks a discerning palate when it comes to
naming, whitespace, or documentation,
it makes all the difference for human collaborators.

_WrenDoc_ takes inspiration from _Swift-flavored Markdown_ and [_Jazzy_](https://github.com/realm/jazzy) to extract documentation markup from special comments inside _Wren_ source-code. Creating _Markdown_ files.

The script just generates markdown files. If you want to create _HTML_ we recommend using [mdBook](https://rust-lang.github.io/mdBook/)

---

Since the early '00s,
[Headerdoc](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/HeaderDoc/intro/intro.html#//apple_ref/doc/uid/TP40001215-CH345-SW1)
has been Apple's preferred documentation standard.

Starting off as little more than a Perl script that parsed trumped-up
[Javadoc](https://en.wikipedia.org/wiki/Javadoc) comments,
Headerdoc would eventually be the engine behind
Apple's developer documentation online and in Xcode.

But like so much of the Apple developer ecosystem,
Swift changed everything.
In the spirit of
_"Out with the old, in with the new"_,
Xcode 7 traded Headerdoc
for fan favorite
[Markdown](https://daringfireball.net/projects/markdown/) ---
specifically, <dfn>Swift-flavored Markdown</dfn>.

## Usage

_WrenDoc_ is a simple _Python_ script that reads _*.wren*_ files and
parse them looking for `/**` comments. Then it extract the comment
contents and store them inside a _Markdown_ file.

You just need [_Python 3_](https://www.python.org/download/releases/3.0/) installed (_MacOS_ and _Linux_ provides a _Python_ installation by default in most cases).

```text
$ cd tools/docs
$ python3 . ../
✨ Jobs Done!: found 9 files. parsed 6 comments. docs saved in `./docs`
```

[Take a peek](https://github.com/NinjasCL/domepunk/wiki/misc.emoji.wren)
at a _WrenDoc_-generated documentation for the `emoji.wren` class.

- Note: The `docs` directory must exist. You can create it before hand `mkdir -p docs`.

### Config

A small [configuration file](https://github.com/NinjasCL/domepunk/blob/main/tools/docs/config.py) is provided.

- `repo`: The base for generating header links to the source code. e.g. _"github.com/ninjascl/domepunk"_
- `branch`: The url related to the branch in the source code. e.g. _"blob/main"_
- `docs`: Tells the directory name for generating the files e.g. _"docs"_

### Special Comments

There are some special comments that could be used at the beginning of the file.
Only one command per line is supported.

- `/** doc-disable */`: This command will disable parsing the file.

- `/** doc-name: MyFilename */`: This command will overwrite the filename of the generated markdown file. By default _WrenDoc_ uses the following format:

```python
# e.g domepunk-misc-emoji-emoji.wren.md
f"{pathToFile}".lower().strip().replace("/", "-").replace("\\", "-") + ".md"`
```

- `/** doc-header */`: This is a special comment that will append its contents on the header of the document.

Example:

```js
/** doc-header
This markdown will append before any other comment.
Useful for giving context.
*/
```

---

## Documentation Comments & Swift-Flavored Markdown

Even if you've never written a line of Markdown before,
you can get up to speed in just a few minutes.
Here's pretty much everything you need to know:

### Basic Markup

Documentation comments look like normal comments,
but with a little something extra.

Multi-line documentation comments
have an extra star in their opening delimiter (`/** ... */`).

Standard Markdown rules apply inside documentation comments:

- Paragraphs are separated by blank lines.
- Unordered lists are marked by bullet characters
  (`-`, `+`, `*`, or `•`).
- Ordered lists use numerals (1, 2, 3, ...)
  followed by either
  a period (`1.`)
  or a right parenthesis (`1)`).
- Headers are preceded by `#` signs
  or underlined with `=` or `-`.
- Both [links](https://daringfireball.net/projects/markdown/syntax#link)
  and [images](https://daringfireball.net/projects/markdown/syntax#img) work.

```swift
/**
    # Lists

    You can apply *italic*, **bold**, or `code` inline styles.

    ## Unordered Lists

    - Lists are great,
    - but perhaps don't nest;
    - Sub-list formatting...

      - ...isn't the best.

    ## Ordered Lists

    1. Ordered lists, too,
    2. for things that are sorted;
    3. Arabic numerals
    4. are the only kind supported.
*/
```

### Summary & Description

The leading paragraph of a documentation comment
becomes the documentation _Summary_.
Any additional content is grouped together into the _Discussion_ section.

If a documentation comment
starts with anything other than a paragraph,
all of its content is put into the Discussion.

### Parameters & Return Values

- **Parameters:**
  Start the line with `Parameter <param name>:`
  and the description of the parameter.
- **Return values:**
  Start the line with `Returns:`
  and information about the return value.
- **Thrown errors:**
  Start the line with `Throws:`
  and a description of the errors that can be thrown.
  it's especially important to document errors properly.

```swift
/**
 Creates a personalized greeting for a recipient.

 - Parameter recipient: The person being greeted.

 - Signature: func greeting(recipient:String) -> String

 - Throws: `MyError.invalidRecipient`
           if `recipient` is "Derek"
           (he knows what he did).

 - Returns: A new string saying hello to `recipient`.
 */
  greeting(recipient) {
    if (recipient == "Derek") {
      return Fiber.abort("MyError.invalidRecipient")
    }
    return "Greetings, %(recipient)!"
  }
```

### Additional Fields

In addition to `Parameters`, `Throws` and `Returns`,
Swift-flavored Markdown
defines a handful of other fields,
which can be loosely organized in the following way:

<dl class="additional-fields">

<dt>Algorithm/Safety Information</dt>
<dd><code>Precondition</code></dd>
<dd><code>Postcondition</code></dd>
<dd><code>Requires</code></dd>
<dd><code>Invariant</code></dd>
<dd><code>Complexity</code></dd>
<dd><code>Important</code></dd>
<dd><code>Warning</code></dd>

<dt>Metadata</dt>
<dd><code>Author</code></dd>
<dd><code>Authors</code></dd>
<dd><code>Copyright</code></dd>
<dd><code>Date</code></dd>
<dd><code>SeeAlso</code></dd>
<dd><code>Since</code></dd>
<dd><code>Version</code></dd>

<dt>General Notes & Exhortations</dt>
<dd><code>Attention</code></dd>
<dd><code>Bug</code></dd>
<dd><code>Experiment</code></dd>
<dd><code>Note</code></dd>
<dd><code>Remark</code></dd>
<dd><code>ToDo</code></dd>

</dl>

### WrenDoc Additions

Some fields were added in order to better document _Wren_ code.

<code>Signature</code>

Since _Wren_ does not have a syntax for type signature. Is recommended to
use _Swift_ syntax to document better the signature for properties
and methods.

The main difference would be using [Wren value types](https://wren.io/values.html) for params and method returns instead _Swift_'s.

**Examples**

The signature for a method that will return the string _"hello, world"_.

- Code:

```js
  sayHelloWorld() {
    return "hello, world"
  }
```

- Signature:

```swift
func sayHelloWorld() -> String
```

The signature for a static property _name_ with the string _"Camilo"_.

- Code:

```js
  static name { "Camilo" }
```

- Signature:

```swift
  static var name: String
```

The signature for a method with an optional parameter. That returns a _Data_ object.

- Code:

```js
  download(useCache) {
    // implementation
  }
```

- Signature:

```swift
  func download(useCache:Bool?) -> Object
```

The signature for a method with an optional parameter and default value
that does not returns a value.

- Code:

```js
  paint(color, times) {
    // implementation
  }
```

- Signature:

```swift
  func paint(color:String? = "#ffffff", times:Num? = 1) -> Void
```

Refer to the [Swift Language Guide](https://docs.swift.org/swift-book/LanguageGuide/Functions.html)
for more details.

### Code blocks

Demonstrate the proper usage or implementation details of a function
by embedding code blocks.
Inset code blocks by at least four spaces:

```swift
/**
    The area of the `Shape` instance.

    Computation depends on the shape of the instance.
    For a triangle, `area` is equivalent to:

        var height = triangle.calculateHeight()
        var area = triangle.base * height / 2
*/
area{_area}
```

Fenced code blocks are also recognized,
delimited by either three backticks (<code>&#96;</code>) or tildes (`~`):

```swift
/**
    The perimeter of the `Shape` instance.

    Computation depends on the shape of the instance, and is
    equivalent to:

    ~~~
    // Circles:
    var perimeter = circle.radius * 2 * Num.pi
    ~~~
*/
perimeter { _perimeter }
```

## MARK / TODO / FIXME

In Objective-C, the preprocessor directive `#pragma mark`
is used to divide functionality into meaningful, easy-to-navigate sections.
In Swift, the same can be accomplished with the comment `// MARK:`. Thus we recommend
implementing it in your code too.

The following comments are :

- `// MARK:`
- `// TODO:`
- `// FIXME:`

As with `#pragma`, marks followed by a single dash (`-`)
are preceded with a horizontal divider. Additionally there are others conventional comment tags,
such as `NOTE` and `XXX`.

> _WrenDoc_ does not recognize this type of comments. But they are useful for separating
> different sections of the code. In the future it may obtain information to generate better docs.

---

Although the tooling and documentation around _Wren_ is still developing,
one would be wise to adopt good habits early,
by using the new _Markdown_ capabilities for documentation,
as well as `MARK:` comments in _Wren_ code going forward.

## Thanks

- This doc is heavily based on [Mattt & Nate Cook](https://github.com/NSHipster/articles/blob/master/2015-05-05-swift-documentation.md) Swift documentation blog post.

## Links

- [Jazzy](https://github.com/realm/jazzy)
- [NSHipster Swift Documentation](https://nshipster.com/swift-documentation/)
- [Swift header documentation in Xcode 7](https://ericasadun.com/2015/06/14/swift-header-documentation-in-xcode-7/)
- [Markup Formatting Reference](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)
- [Swift Docc](https://www.swift.org/documentation/docc/formatting-your-documentation-content)
- [Swift Documentation Comments](https://github.com/swiftlang/swift/blob/main/docs/DocumentationComments.md)
- [Mdbook](https://rust-lang.github.io/mdBook/)
