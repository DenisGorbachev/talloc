import _ from 'lodash'
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

### Test helpers ###

export step = (functor, taskPattern, executor = null) ->
  await functor.reexecute()
  task = _.first(functor.tasks)
  expect(task).toMatchObject(_.defaults(taskPattern, { priority: 10, genome: [] }))
  if executor
    await executor(task)
  else
    await complete(task)

export complete = (task, db) ->
  switch task.type
    when 'CreateArtefact'
      result = await db.Artefacts.insertOne(task.context.blueprint)
      result.insertedId
    when 'CreateChannelOwner'
      result = await db.Persons.insertOne(task.context.blueprint)
      result.insertedId
    when 'CreatePrivateChannelWithOwner'
      result = await db.Persons.insertOne(task.context.blueprint)
      result.insertedId
    else
      throw new Error("Can't complete #{task.type} task")
