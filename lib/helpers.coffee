import Joi from '@hapi/joi'

export joi = Joi.defaults((schema) -> schema.required())

export display = (tasks, level) ->
  for task in tasks
    console.info(' '.repeat(level * 2) + '- ' + task.type)
    display(task.children, level + 1)

export toMarkdownList = (array) -> array.map((v) -> '* ' + v).join('\n')

export perms = (type, truePermissions, personIds = []) ->
  permissions = { type, personIds }
  for permission in ['create', 'read', 'update', 'delete']
    permissions[permission] = permission in truePermissions or truePermissions is true or truePermissions is 'all'
  permissions
