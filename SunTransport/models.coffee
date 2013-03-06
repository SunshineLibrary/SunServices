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

media = {
  tableName: 'media'
  , keys: ['uuid']
  , fields: []
}

exports.models = [admins, pieces, images, media]