import moment from 'moment'
import { MongoClient } from 'mongodb'
import MaintainHealth from '../src/Functor/MaintainHealth'
import { perms } from '../src/helpers'
import { complete } from '../src/test_helpers'

describe 'MaintainHealth', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, { useNewUrlParser: true })
    db = await connection.db(global.__MONGO_DB_NAME__)
    db.Users = db.collection('Users')
    db.Acts = db.collection('Acts')

  afterAll ->
    await db.close()
    await connection.close()

  it 'should return the task', ->
    deps = { db, now: new Date('2019-07-26T00:00:00Z') }

    functor = new MaintainHealth({
    # no params
    }, deps)
    {
      insertedId: aliceId
    } = await db.Users.insertOne(
      emails: [
        { address: 'alice@example.com', verified: true }
      ]
    )
    alice = await db.Users.findOne({ _id: aliceId })

    task = await functor.getNextTask(alice)
    expect(task).toMatchObject(
      type: 'CreateAct',
      context:
        blueprint:
          type: 'MorningExercise'
        title: "Do morning exercises"
    )

    await db.Acts.insertOne(
      type: 'MorningExercise'
      userId: alice._id
      createdAt: moment(deps.now).subtract(2, 'days').toDate()
    )

    task = await functor.getNextTask(alice)
    expect(task).toMatchObject(
      type: 'CreateAct',
      context:
        blueprint:
          type: 'MorningExercise'
        title: "Do morning exercises"
    )
    await complete(task, deps)

    task = await functor.getNextTask(alice)
    expect(task).toBeUndefined()

  # Jest requires `describe` callback to return undefined
  return undefined
