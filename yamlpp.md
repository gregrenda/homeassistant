# yamlpp

`yamlpp` is a preprocessor for [YAML](https://yaml.org) files.  It's loosely
based on the C preprocessor.  `yamlpp` was developed to generate yaml
configuration files for [Home Assistant](https://www.home-assistant.io) but
it might be useful for other applications.

Features:
- comments
- line splicing
- `#if / #endif` directives
- `#define` macros with and without parameters
- `#undef`
- `#include`
- Perl expression evaluation

## Usage

`yamlpp` takes its input from standard input or one or more files specified
on the command line.  The input is parsed consuming macro definitions,
eliminating comments, splicing lines, processing conditional blocks and
expanding macro invocations and Perl expressions.  The result is sent to
the standard output.

### Comments

Comments are indicated by `//` (with optional preceding whitespace).
Comments are eliminated from the output and, if the line consisted only of a
comment, the entire line will be eliminated.

<pre>
    // This line will be eliminated
    this line has a trailing comment // which will be eliminated
</pre>
will be output as
<pre>
    this line has a trailing comment
</pre>

### Line splicing

If a line ends with `\\`, the `\\` is eliminated and the following line is
appended, squashing any whitespace preceding the `\\` and any leading
whitespace on the following line to a single space.

<pre>
    This is the first line.    \\
      This is the second line. \\
        This is the third line.
</pre>
will be output as
<pre>
    This is the first line. This is the second line. This is the third line.
</pre>

### Conditionals

The `#if` and `#endif` directives allow lines to be conditionally eliminated
from the output.  This can be used for debugging or block commenting
purposes.  The expression following the `#if` is evaluated and, if true
(for Perl's concept of true), the following lines up to the terminating
`#endif` will be output.  Otherwise, those lines will be eliminated.

<pre>
#if 0
  These lines
  will be eliminated
  from the output
#endif

#if 1
  These lines
  will be included
  in the output
#endif
</pre>

### Macros

Macros are declared using the `#define` directive.  There are two types of
macros.

#### Simple macros

Simple macros take no parameters and consist of a single line (or multiple
lines joined by line splicing `\\`) of replacement text.  Simple macros are
expanded after complex macros so that a simple macro with replacement text
containing commas can be passed as a parameter to complex macros.
Simple macros can include other macros.  Simple macros can also be defined
on the `yamlpp` command line with the `-D` option:
`yamlpp -DMACRO_NAME=value -DANOTHER_MACRO=value file.ypp`

<pre>
#define SIMPLE_MACRO_1	this is a simple macro

#define SIMPLE_MACRO_2	this is a multiline \\
			simple macro

#define SIMPLE_MACRO_3	this macro includes another macro: SIMPLE_MACRO_1

Here's an example of a simple macro "SIMPLE_MACRO_1"

This is a multiline simple macro "SIMPLE_MACRO_2"

This macro includes another macro "SIMPLE_MACRO_3"
</pre>
will be output as
<pre>
Here's an example of a simple macro "this is a simple macro"

This is a multiline simple macro "this is a multiline simple macro"

This macro includes another macro "this macro includes another macro: this is a simple macro"
</pre>

#### Complex macros

Complex macro declarations can include optional parameters and consist of
multiple lines with each line except the last ending with a `\`.  Within
the declaration strings of the form `<<parameter>>` will be replaced with
the parameter when the macro is invoked.  The indentation of the first line
of the macro declaration is stripped from all lines.  When the macro is
invoked, the indentation of the invoking line will be prepended to the
expanded lines of the macro.  Complex macros can include other macros.

<pre>
#define BAZ	baz simple macro

#define BAR(_d) \
  BAR macro parameter _d = <<_d>>

#define FOO(_a, _b, _c) \
  FOO macro parameter _a = <<_a>> \
  FOO macro parameter _b = <<_b>> \
    BAR(<<_c>>) \
    simple macro: BAZ

FOO(first, second, third)

Here's an invocation that's indented

    FOO(huey, dewey, louie)

Passing a parameter containing commas

#define ARG_WITH_COMMAS larry, moe, curly

FOO(huey, dewey, ARG_WITH_COMMAS)
</pre>
will be output as
<pre>
FOO macro parameter _a = first
FOO macro parameter _b = second
  BAR macro parameter _d = third
  simple macro: baz simple macro

Here's an invocation that's indented

    FOO macro parameter _a = huey
    FOO macro parameter _b = dewey
      BAR macro parameter _d = louie
      simple macro: baz simple macro

Passing a parameter containing commas


FOO macro parameter _a = huey
FOO macro parameter _b = dewey
  BAR macro parameter _d = larry, moe, curly
  simple macro: baz simple macro
</pre>

##### Sequenced macros

A macro invocation with the first parameter of the form `n..n` will be
expanded as if there were multiple invocations for each digit in the range
from n to n.
<pre>
FOO(1..4, arg1, arg2)
</pre>
is equivalent to
<pre>
FOO(1, arg1, arg2)
FOO(2, arg1, arg2)
FOO(3, arg1, arg2)
FOO(4, arg1, arg2)
</pre>

##### Undefining a macro

A macro may be undefined using the `#undef` directive
<pre>
#undef FOO
</pre>

### Include files

A file may be included using the `#include` directive.  The included file
will be indented by the number of spaces preceding the `#` in the directive.
Included files may contain `#include` directives.

Given the file `foo`
<pre>
line 1
line 2
line 3
</pre>
the directives
<pre>
#include foo
    #include foo
</pre>
will be output as
<pre>
line 1
line 2
line 3
    line 1
    line 2
    line 3
</pre>

### Perl expression evaluation

The construct `(|expression|)` will be replaced with the results of the
Perl evaluation of the expression.

<pre>
some math: 2 + 2 = (|2 + 2|)
some string manipulation: (|lc 'This Is All Lower Case'|)
</pre>
will be output as
<pre>
some math: 2 + 2 = 4
some string manipulation: this is all lower case
</pre>
