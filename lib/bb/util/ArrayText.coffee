class window.aurora.ArrayText
  @emit: (input, delims = null, indenter = "") ->
    dim = if delims? then delims.length else 0
    ind = ""

    switch dim
      when 0 then input.toString()
      when 1 then input.join(delims[0])
      when 2
        ind = indenter + "  "
        ind + _.map(input, (a) -> emit(a, delims.slice(1,2), indenter)).join(delims[0] + ind)
      when 3
        ind = indenter + "  "
        ind + _.map(input, (a) -> _.map(a,(a1) -> a1.join(delims[2])).join(delims[1])).join(delims[0] + ind)
      else input.toString()