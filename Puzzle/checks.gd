tool


# check if line completely matches clue
static func check_line_completed(clue: Array, cells_s: String):
	var regex_string = "^[_X]*O{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+O{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
#	print("checking complete pattern %s on %s" % [pattern.get_pattern(), cells_s])
	return pattern.search(cells_s)


# check if line incompletely matches clue
static func check_line_possible(clue: Array, cells_s: String):
	var regex_string = "^[_X]*[O_]{%s}" % clue[0]
	if len(clue) > 1:
		for n in clue.slice(1, -1):
			regex_string += "[_X]+[O_]{%s}" % n
	regex_string += "[_X]*$"
	var pattern = RegEx.new()
	pattern.compile(regex_string)
#	print("checking partial pattern %s on %s" % [pattern.get_pattern(), cells_s])
	return pattern.search(cells_s)


# if there's only one clue, check that it is matched and return that cell true/false
# if the line is completed return each cell true
# if the line is impossible return each cell false
# for each clue, check that it could fit the line and return true/false for each cell
# 
# TODO: optimize so that regex patterns are only built once when the clue is set
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
		_: #middle clue, idk, just check that it's in there?
			#probably needs more than is easy to do with regex
			regex_string += "^(?<pre>"
			for j in range(len(clue)):
				if j == i:
					regex_string += "X)(?<posn>O{%s})X" % clue[j]
				elif j == 0:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				elif j == i + 1:
					regex_string += "[_X]*[O_]{%s}" % clue[j]
				else:
					regex_string += "[_X]+[O_]{%s}" % clue[j]
			regex_string += "[X_]*$"
	var pattern := RegEx.new()
	pattern.compile(regex_string)
#	var matches = pattern.search_all(cells_s)
#	return len(matches) == 1
	var i_match := pattern.search(cells_s)
	if not i_match:
		return false
	var i_match_idx := len(i_match.get_string("pre"))
#	assert(not i_match)
	# have: clue i fits at position x
	# want: only clue i fits at position x
	
	# for each other clue, check if clues before and after that clue fit in the string before and after the original match
	var pre_cells := cells_s.substr(0, i_match_idx)
	var post_cells := cells_s.substr(i_match_idx + clue[i])
#	print("clues:%s" % [clue])
#	print("pre:  %s" % pre_cells)
#	print("post: %s" % post_cells)
	for j in range(len(clue)):
		if j == i or clue[j] != clue[i]:
#			print("%s is i" % j)
			continue
		elif j == 0:
#			print(clue.slice(j + 1, len(clue) - 1))
			if check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
		elif j == len(clue) - 1:
#			print(clue.slice(0, j - 1))
			if check_line_possible(clue.slice(0, j - 1), pre_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
		else:
#			print(clue.slice(0, j - 1), clue.slice(j + 1, len(clue) - 1))
			if check_line_possible(clue.slice(0, j - 1), pre_cells) and check_line_possible(clue.slice(j + 1, len(clue) - 1), post_cells):
#				print("%s fits" % j)
				return false
#			print("%s doesn't fit" % j)
	return true


static func _test_check_each_clue(clue: Array, cells_s: String, expected: Array):
	assert(len(clue) == len(expected))
	var result := check_each_clue(clue, cells_s)
	if result == expected:
		# print("Pass!\n")
		return true
	else:
		print("######\nClue: %s\nCells: %s\nExpected: %s" % [clue, cells_s, expected])
		print("Failed, got: %s" % [result])
		return false


static func invert_string(s: String) -> String:
	var ret := ""
	for i in range(len(s) - 1, -1, -1):
		ret += s[i]
	return ret


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
	]
	var reversed_test_cases := []
	for test_case in test_cases:
		var reversed_case := {
			clue = test_case.clue.duplicate(),
			cells_s = invert_string(test_case.cells_s),
			expected = test_case.expected.duplicate(),
		}
		reversed_case.clue.invert()
		reversed_case.expected.invert()
		reversed_test_cases.append(reversed_case)
	var passed := 0
	var failed := 0
	for test_case in test_cases: #+ reversed_test_cases:
		var result = _test_check_each_clue(test_case.clue, test_case.cells_s, test_case.expected)
		if result:
			passed += 1
		else:
			failed += 1
