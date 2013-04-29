pieces = {
  tableName: 'pieces'
  , keys: ['uuid']
  , fields: [
    'creator_id', 'subject_id'
    , 'textbook_node_id'
    , 'name', 'piece_type'
    , 'description', 'medium_id'
    , 'updated_at', 'created_at'
  ]
}

admins = {
  tableName: 'admins'
  , keys: ['uuid']
  , fields: [
    'school_id', 'name', 'is_manager'
    , 'created_at', 'updated_at'
  ]
}

images = {
  tableName: 'images'
  , keys: ['uuid']
  , fields: [
    'seq', 'description'
    , 'medium_id', 'piece_id'
    , 'created_at', 'updated_at'
  ]
}

activities = {
  tableName: 'activities'
  , keys: ['uuid']
  , fields: ['medium_id']
}

problems = {
  tableName: 'problems'
  , keys: ['uuid']
  , fields: ['medium_id']
}

media = {
  tableName: 'media'
  , keys: ['uuid']
  , fields: []
}

exports.models = [admins, pieces, images, activities, problems, media]
