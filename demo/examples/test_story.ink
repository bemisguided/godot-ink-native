// Comprehensive test story for godot-ink-cpp
// Tests all major API features: variables, choices, tags, navigation, state management

# title: Comprehensive Test Story
# author: Test Suite
# version: 1.0

// Variables of all supported types
VAR score = 0
VAR health = 100.0
VAR has_key = false
VAR player_name = "Hero"

// === OPENING ===
// Linear section with multiple lines and tags

Welcome to the comprehensive test story! # scene: opening # mood: welcoming
This story tests all InkStory features.
Your adventure begins now.

-> hub

// === HUB ===
// Central location with multiple paths

=== hub ===
# location: hub
# scene: crossroads

You stand at a crossroads. # mood: contemplative
Current status - Score: {score}, Health: {health}, Name: {player_name}

+ [Go north] -> north_path
+ [Go south] -> south_path
+ [Go east] -> east_path
+ [Check status] -> check_status
+ {has_key} [Use the key] -> victory
+ [Rest and recover] -> rest

// === NORTH PATH ===
// Tests variable modification and stitches

=== north_path ===
# location: north
# scene: forest

You venture into the northern forest. # mood: mysterious
The trees grow dense around you.
~ score += 10
~ health -= 5.5

* [Continue deeper] -> north_path.deeper
* [Turn back] -> hub

= deeper
# location: deep_forest

You press on into the depths.
~ score += 5
The forest opens into a clearing.

-> hub

// === SOUTH PATH ===
// Tests item acquisition and boolean variables

=== south_path ===
# location: south
# scene: ruins

You head south toward ancient ruins. # mood: tense
Among the rubble, you discover a golden key! # action: discovery
~ has_key = true
~ score += 15

* [Take the key and return] -> hub

// === EAST PATH ===
// Tests string variables and conditional text

=== east_path ===
# location: east
# scene: village

You arrive at a small village.
An old man greets you.

+ [Ask about your quest]
    "Greetings, {player_name}!" he says.
    {has_key: "I see you found the key! Well done!"|"You'll need to find the ancient key."}
    -> hub

+ [Ask to change your name] -> change_name

// === NAME CHANGE ===
// Tests string variable modification

=== change_name ===
"What name do you prefer?"

+ [Choose 'Warrior']
    ~ player_name = "Warrior"
    "Very well, {player_name}."
    -> hub

+ [Choose 'Mage']
    ~ player_name = "Mage"
    "Very well, {player_name}."
    -> hub

+ [Keep current name]
    "As you wish, {player_name}."
    -> hub

// === STATUS CHECK ===
// Tests variable reading and conditional display

=== check_status ===
You check your status:

Name: {player_name}
Score: {score}
Health: {health}
{has_key: Has key: Yes|Has key: No}

* [Continue] -> hub

// === REST ===
// Tests float variable modification

=== rest ===
# scene: rest

You sit down to rest. # mood: peaceful
You feel your strength returning.
~ health += 25.0
~ score += 2

Health restored! Current health: {health}

* [Stand up] -> hub

// === VICTORY ===
// Tests story ending

=== victory ===
# scene: finale
# mood: triumphant

You use the golden key!
A hidden door swings open before you.

Congratulations, {player_name}! # action: celebration
You completed the quest with {score} points!

-> END

// === DEAD END ===
// For testing unreachable paths

=== dead_end ===
This path should not be reachable in normal play.
It exists for testing path navigation.
-> END

// === LOOP TEST ===
// For testing loops and sticky choices

=== loop_test ===
# location: loop

This is a looping section.

+ [Loop option 1] -> loop_test
+ [Loop option 2] -> loop_test
+ [Exit loop] -> hub

// === MULTI TAG LINE ===
// For testing multiple tags on same line

=== multi_tag_test ===
This line has multiple tags. # tag1: value1 # tag2: value2 # tag3: value3
-> hub
