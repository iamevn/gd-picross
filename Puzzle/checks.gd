# functions to check clues against a line, use check_each_clue()
# _test() can be used to run tests
# TODO(#1): optimize so that regex patterns are only built once when the clue is set

tool


const util = preload("util.gd")


# if there's only one clue, check that it is matched and return that cell true/false
# if the line is completed return each cell true
# if the line is impossible return each cell false
# for each clue, check that it could fit the line and return true/false for each cell
static func check_each_clue(clue: Array, cells_s: String) -> Array:
	if len(clue) == 1:
		return [check_line_completed(clue, cells_s)]
	var checked := []
	if check_line_completed(clue, cells_s):
		for n in range(len(clue)):
			checked += [true]
	elif not check_line_possible(clue, cells_s):
		for n in range(len(clue)):
			checked += [false]
	else:
		for i in range(len(clue)):
			checked += [check_single_subclue(i, clue, cells_s)]
	return checked


# true if clue at index i in clue array is unambiguously fulfilled by cells_s string
# false otherwise
static func check_single_subclue(i: int, clue: Array, cells_s: String) -> bool:
	var clue_count := len(clue)
	var last_clue_idx := clue_count - 1
	var regex_string := ""
	# check if i fits
	match i:
		0: #first clue, match against left edge, soft match rest of clues
			regex_string += "^(?<pre>(?:[_X]*X)?)(?<posn>O{%s})X[_X]*[O_]{%s}" % [clue[0], clue[1]]
			if clue_count > 2:
				for n in clue.slice(2, -1):
					regex_string += "[_X]+[O_]{%s}" % n
			regex_string += "[_X]*$"
		last_clue_idx: #last clue, match against right edge, soft match rest of clues
			regex_string += "^(?<pre>[_X]*[O_]{%s}" % clue[0]
			if clue_count > 2:
				for n in clue.slice(1, -2):
					regex_string += "[_X]+[O_]{%s}" % n
			regex_string += "[_X]*X)(?<posn>O{%s})(?:X[_X]*)?$" % clue[-1]
		_: #middle clue, soft match all other clues
			regex_string += "^(?<pre>"
			for j in range(len(clue)):
				if j == i:
					regex_string += "[_X]*X)(?<posn>O{%s})X" % clue[j]
				elif j == 0:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				elif j == i + 1:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				else:
					regex_string += "[_X]+[O_]{%s}" % clue[j]
			regex_string += "[X_]*$"
	var pattern := RegEx.new()
	pattern.compile(regex_string)
	var i_match := pattern.search(cells_s)
	if not i_match:
		return false
	# use the pre group to get the position of the clue match
	var i_match_idx := len(i_match.get_string("pre"))
	# have: clue i fits at position i_match_idx
	# want: only clue i fits at position i_match_idx
	return check_unambiguous_placement(i, i_match_idx, clue, cells_s)


# for each other clue, check if clues before and after that clue fit in 
# the string before and after the potential match position
# return true if only i fits in spot potential_i_idx
# return false if another clue would fit in spot potential_i_idx
static func check_unambiguous_placement(i: int, potential_i_idx: int, clue: Array, cells_s: String):
	var pre_cells := cells_s.substr(0, potential_i_idx)
	var post_cells := cells_s.substr(potential_i_idx + clue[i])
	for j in range(len(clue)):
		if j == i or clue[j] != clue[i]:
			# i is j or j's size doesn't match i's size, skip
			continue
		elif j == 0:
			# does all but the first clue fit in the space after potential match?
			# does the spot before the potential match work for no clues
			if check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells) and check_line_possible([], pre_cells):
#				# first clue fits here, clue i is ambiguous
				return false
		elif j == len(clue) - 1:
			# does all but the last clue fit in the space before potential match?
			# does the spot after the potential match work for no clues
			if check_line_possible(clue.slice(0, j - 1), pre_cells) and check_line_possible([], post_cells):
				# last clue fits here, clue i is ambiguous
				return false
		else:
			# do clues before j fit in the space before potential match?
			# do clues after j fit in the space after potential match?
			if check_line_possible(clue.slice(0, j - 1), pre_cells) and check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells):
#				# clue j fits here
				return false
	return true


# check if line completely matches clue
# true if all O's are filled. X's may just be blank/marked
# false if not enough O's are filled for the clues
static func check_line_completed(clue: Array, cells_s: String):
	if len(clue) == 1 and clue[0] == 0:
		return check_line_has_no_filled_spaces(cells_s)
	var regex_string = "^[_X]*O{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+O{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
	return pattern.search(cells_s)


# check if line incompletely matches clue
# true if line can be completed by adding O's
# false if it's impossible to only add O's and finish the line,
# either because wrong O's are already there or X's block O's
static func check_line_possible(clue: Array, cells_s: String):
	if len(clue) == 0 or (len(clue) == 1 and clue[0] == 0):
		return check_line_has_no_filled_spaces(cells_s)
	var regex_string = "^[_X]*[O_]{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+[O_]{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
	return pattern.search(cells_s)


# can this set of cells match an empty clue
# true if there are no filled spaces in cells
# false if there are some filled space(s) in cells
static func check_line_has_no_filled_spaces(cells_s: String):
	var regex_string = "^[X_]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
	return pattern.search(cells_s)


static func _test_check_each_clue(clue: Array, cells_s: String, expected: Array) -> bool:
	assert(len(clue) == len(expected))
	var result := util.map_bool(check_each_clue(clue, cells_s))
	if result == expected:
		# print("Pass!\n")
		return true
	else:
		print("######\nClue: %s\nCells: %s\nExpected: %s" % [clue, cells_s, expected])
		print("Failed, got: %s" % [result])
		return false


# true if all test cases pass, false if some fail
static func _test():
	var test_cases := [
		{
			clue = [1, 1, 1],
			cells_s = "OXO_O_",
			expected = [true, true, true],
		},
		{
			clue = [1, 1, 1],
			cells_s = "______",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "OX____",
			expected = [true, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "O_____",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "XOX___",
			expected = [true, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "_OX___",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "OXXX__",
			expected = [false, false, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "__XOX_",
			expected = [false, true, false],
		},
		{
			clue = [1, 1, 1],
			cells_s = "__XOX___",
			expected = [false, false, false],
		},
		{
			clue = [1, 4],
			cells_s = "_XOX_______",
			expected = [true, false],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "__XOX______",
			expected = [false, false, false, false],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "____XOXOXOX",
			expected = [false, true, true, true],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "XX_XXOXOXOX",
			expected = [false, true, true, true],
		},
		{
			clue = [1, 1, 1, 1],
			cells_s = "___XXOXOXOX",
			expected = [false, true, true, true],
		},
		{
			clue = [0],
			cells_s = "___XXOXOXOX",
			expected = [false],
		},
		{
			clue = [0],
			cells_s = "_X",
			expected = [true],
		},
		{
			clue = [0],
			cells_s = "X",
			expected = [true],
		},
		{
			clue = [0],
			cells_s = "O",
			expected = [false],
		},
		{
			clue = [0],
			cells_s = "_",
			expected = [true],
		},
	]
	var reversed_test_cases := []
	for test_case in test_cases:
		var reversed_case := {
			clue = test_case.clue.duplicate(),
			cells_s = util.invert_string(test_case.cells_s),
			expected = test_case.expected.duplicate(),
		}
		reversed_case.clue.invert()
		reversed_case.expected.invert()
		reversed_test_cases.append(reversed_case)
	var passed := 0
	var failed := 0
	for test_case in test_cases + reversed_test_cases:
		var result := _test_check_each_clue(test_case.clue, test_case.cells_s, test_case.expected)
		if result:
			passed += 1
		else:
			failed += 1
	print("######\nPassed: %s, Failed: %s\n######\n\n" % [passed, failed])
	return failed == 0
