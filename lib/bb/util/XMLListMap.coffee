class window.aurora.XMLListMap
  @from: (xl) ->
    mapper = new window.aurora.XMLListMap
    mapper.xmllist = xl
    mapper

  to_a: (f, args...) ->
    _.map(@xmllist, f, args)