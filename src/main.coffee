



############################################################################################################
TYPES                     = require 'coffeenode-types'
#...........................................................................................................
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
log                       = TRM.log.bind TRM
echo                      = TRM.echo.bind TRM


#-----------------------------------------------------------------------------------------------------------
misfit = {}

#-----------------------------------------------------------------------------------------------------------
@new_registry = ->
  R =
    '~isa':           'TAG/registry'
    'entry-by-id':    {}
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@_register = ( me, entry ) ->
  id = entry[ 'id' ]
  throw new Error "entry with ID #{rpr id} already registered" if me[ 'entry-by-id' ][ id ]?
  me[ 'entry-by-id' ][ id ] = entry
  return null

#-----------------------------------------------------------------------------------------------------------
@new_tag = ( me, id, name, rules ) ->
  R =
    '~isa':       'TAG/tag'
    'id':         id
    'name':       name
    'rules':      rules ? {}
    'oids':       {}
  #.........................................................................................................
  @_register me, R
  return R

#-----------------------------------------------------------------------------------------------------------
@new_object = ( me, id, name, attributes ) ->
  R =
    '~isa':       'TAG/object'
    'id':         id
    'name':       name
    'attributes': attributes ? {}
    'tids':       {}
  #.........................................................................................................
  @_register me, R
  return R

#-----------------------------------------------------------------------------------------------------------
@link = ( me, ids... ) ->
  [ tags, objects, ]  = @_get_tags_and_objects me, ids...
  link_count          = 0
  #.........................................................................................................
  for tag in tags
    for object in objects
      link_count += @_link me, tag, object
  #.........................................................................................................
  return link_count

#-----------------------------------------------------------------------------------------------------------
@_link = ( me, tag, object ) ->
  return 0 if tag[    'oids' ][ object[ 'id' ] ]?
  tag[    'oids' ][ object[ 'id' ] ] = 1
  object[ 'tids' ][    tag[ 'id' ] ] = 1
  return 1

#-----------------------------------------------------------------------------------------------------------
@is_linked = ( me, tag0, tag1 ) ->
  entries = @_get_tags_and_objects me, tag0, tag1
  return @_is_linked me, entries[ 0 ][ 0 ], entries[ 1 ][ 0 ]

#-----------------------------------------------------------------------------------------------------------
@_is_linked = ( me, tag, object ) ->
  return tag[ 'oids' ][ object[ 'id' ] ]?

#-----------------------------------------------------------------------------------------------------------
@all_linked = ( me, ids... ) ->
  [ tags, objects, ] = @_get_tags_and_objects me, ids...
  #.........................................................................................................
  for tag in tags
    for object in objects
      return false unless @_is_linked me, tag, object
  #.........................................................................................................
  return true

#-----------------------------------------------------------------------------------------------------------
@any_linked = ( me, ids... ) ->
  [ tags, objects, ] = @_get_tags_and_objects me, ids...
  #.........................................................................................................
  for tag in tags
    for object in objects
      return true if @_is_linked me, tag, object
  #.........................................................................................................
  return false

#-----------------------------------------------------------------------------------------------------------
@get = ( me, id, fallback = misfit ) ->
  return me, id, null, fallback

#-----------------------------------------------------------------------------------------------------------
@_get = ( me, id, type, fallback ) ->
  R = me[ 'entry-by-id' ][ id ]
  if R?
    TYPES.validate R, type if type?
  else
    return fallback unless fallback is misfit
    throw new Error "unknown ID #{rpr id}"
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@get_object = ( me, id, fallback = misfit ) ->
  R = @get me, id
  unless R is misfit or ( type = TYPES.type_of object ) is 'TAG/object'
    throw new Error "ID #{rpr id} is a #{rpr type}, not a 'TAG/object'"
  return R

#-----------------------------------------------------------------------------------------------------------
@get_tag = ( me, id, fallback = misfit ) ->
  R = @get me, id
  unless R is misfit or ( type = TYPES.type_of object ) is 'TAG/tag'
    throw new Error "ID #{rpr id} is a #{rpr type}, not a 'TAG/tag'"
  return R


#-----------------------------------------------------------------------------------------------------------
@tids_of = ( me, oid ) ->
  object = @get_object me, oid
  #.........................................................................................................
  # could use `Object.keys`
  return ( tid for tid of object[ 'tids' ] )

#-----------------------------------------------------------------------------------------------------------
@oids_of = ( me, object ) ->
  unless ( type = TYPES.type_of object ) is 'TAG/object'
    throw new Error "unable to get tag IDs from value of type #{rpr type}"
  #.........................................................................................................
  # could use `Object.keys`
  return ( tid for tid of object[ 'tids' ] )

#-----------------------------------------------------------------------------------------------------------
@tags_of = ( me, ids... ) ->
  [ tags, objects, ] = @_get_tags_and_objects me, ids...
  #.........................................................................................................
  for tag in tags
    for object in objects
      return true if @_is_linked me, tag, object
  #.........................................................................................................
  return false

#-----------------------------------------------------------------------------------------------------------
@_get_tags_and_objects = ( me, ids... ) ->
  entry_by_id = me[ 'entry-by-id' ]
  tags        = []
  objects     = []
  R           = [ tags, objects, ]
  #.........................................................................................................
  for id in ids
    entry = entry_by_id[ id ]
    throw new Error "unknown ID #{rpr id}" unless entry?
    #.......................................................................................................
    switch type = TYPES.type_of entry
      #.....................................................................................................
      when 'TAG/tag'
        tags.push entry
      #.....................................................................................................
      when 'TAG/object'
        objects.push entry
      #.....................................................................................................
      else
        throw new Error "unable to handle value of type #{rpr type}"
  #.........................................................................................................
  throw new Error    "no tags found in #{rpr ids}" unless    tags.length > 0
  throw new Error "no objects found in #{rpr ids}" unless objects.length > 0
  #.........................................................................................................
  return R

# #-----------------------------------------------------------------------------------------------------------
# @unset = ( me, oids... ) ->
#   my_id         = me[ 'id' ]
#   my_entry_ids  = me[ 'entry-ids' ]
#   for entry in oids
#     delete my_entry_ids[ entry[ 'id' ] ]
#     delete entry[ 'tids' ][ my_id ]


