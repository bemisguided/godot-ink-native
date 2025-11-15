// Test story for external function bindings
// Tests various arities and return types

EXTERNAL get_player_name()
EXTERNAL roll_dice()
EXTERNAL add(a, b)
EXTERNAL multiply(x, y)
EXTERNAL concat(str1, str2)
EXTERNAL is_lucky()
EXTERNAL void_function()

-> start

=== start ===
Welcome to the external functions test!

Your name is: {get_player_name()}

You roll the dice... you got {roll_dice()}!

Let's do some math: 5 + 3 = {add(5, 3)}
And multiplication: 4 * 7 = {multiply(4, 7)}

String concatenation: {concat("Hello", " World")}

Are you lucky today? {is_lucky()}

~ void_function()
(Void function called with no visible output)

-> hub

=== hub ===
What would you like to test?

+ [Test zero-arg function] -> test_zero_arg
+ [Test multi-arg function] -> test_multi_arg
+ [Test string return] -> test_string
+ [Test boolean return] -> test_boolean
+ [Done] -> END

=== test_zero_arg ===
Your name is: {get_player_name()}
Rolling dice: {roll_dice()}
-> hub

=== test_multi_arg ===
10 + 20 = {add(10, 20)}
6 * 9 = {multiply(6, 9)}
-> hub

=== test_string ===
Combining strings: {concat("Godot", " + Ink")}
-> hub

=== test_boolean ===
Lucky check: {is_lucky()}
-> hub
