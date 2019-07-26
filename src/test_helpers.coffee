import _ from 'lodash'

export complete = (task, { db, now }) ->
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
    when 'SendMessage'
      result = await db.Messages.insertOne(task.context.blueprint)
      result.insertedId
    when 'CreateAct'
      result = await db.Acts.insertOne(_.defaults(task.context.blueprint, { updatedAt: now, createdAt: now }))
      result.insertedId
    else
      throw new Error("Can't complete #{task.type} task")

export step = (functor, taskPattern, executor = null) ->
  await functor.reexecute()
  task = _.first(functor.tasks)
  expect(task).toMatchObject(_.defaults(taskPattern, { priority: 10, genome: [] }))
  if executor
    await executor(task)
  else
    await complete(task)
