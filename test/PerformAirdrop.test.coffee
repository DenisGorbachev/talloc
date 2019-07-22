import _ from 'lodash'
import moment from 'moment'
import { MongoClient } from 'mongodb'
import PerformAirdrop from '../lib/Functor/PerformAirdrop'
import { perms } from '../lib/helpers'

describe 'PerformAirdrop', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, { useNewUrlParser: true })
    db = await connection.db(global.__MONGO_DB_NAME__)
    db.Users = db.collection('Users')
    db.Persons = db.collection('Persons')
    db.Projects = db.collection('Projects')
    db.Channels = db.collection('Channels')
    db.Messages = db.collection('Messages')
    db.Artefacts = db.collection('Artefacts')
    db.Assets = db.collection('Assets')
    db.Transactions = db.collection('Transactions')

  afterAll ->
    await connection.close()
    await db.close()

  it 'should return the task for denis.d.gorbachev@gmail.com', ->
    functor = new PerformAirdrop({
      projectUid: 'BTCV',
      networks: ['Twitter', 'Facebook', 'Telegram', 'Discord']
      assetUid: 'MOON',
      limit: 1000,
      from: new Date('2019-07-22'),
      to: new Date('2019-07-31'),
      referralLimit: 100,
    }, { db })
    await db.Projects.insertOne(
      uid: 'BTCV',
      url: 'https://btcv.volatility-tokens.com/',
    )
    await db.Assets.insertOne(
      uid: 'BTCV',
      maxSupply: 100000000,
      circulatingSupply: 9117300,
      initialOfferingPrice: 0.03 # USD
    )
    await db.Assets.insertOne(
      uid: 'MOON',
      maxSupply: 10000000000,
      circulatingSupply: 10000000000,
      initialOfferingPrice: 0.001 # USD
    )
    #    await functor.reexecute()
    #    expect(_.first(functor.tasks)).toMatchObject(
    #      type: 'SetField',
    #      context: {}
    #      priority: 10,
    #      genome: []
    #    )
    {
      insertedId: airdropsIOOwnerId
    } = await db.Persons.insertOne(
      name: ''
    )
    await db.Channels.insertOne(
      uid: 'airdrops.io'
      network: 'Internet'
      name: 'Airdrops.io'
      tags: ['Airdrop']
      permissions: [
        perms('public', ['read'])
        perms('protected', ['read'])
        perms('private', 'all', [airdropsIOOwnerId])
      ]
    )
    await db.Channels.insertOne(
      uid: 'https://airdrops.io/contact/'
      network: 'Form'
      name: 'Airdrops.io contact form'
      tags: ['Listing']
      permissions: [
        perms('public', ['create'])
        perms('private', 'all', [airdropsIOOwnerId])
      ]
    )
    await db.Channels.insertOne(
      uid: 'mail@airdrops.io'
      network: 'Email'
      name: 'Airdrops.io listings email'
      tags: ['Listing']
      permissions: [
        perms('public', ['create'])
        perms('private', 'all', [airdropsIOOwnerId])
      ]
    )
    await db.Channels.insertOne(
      uid: 'AirdropsTeam'
      network: 'Telegram'
      name: 'Airdrops.io listings Telegram'
      tags: ['Listing']
      permissions: [
        perms('public', ['create'])
        perms('private', 'all', [airdropsIOOwnerId])
      ]
    )
    await functor.reexecute()
    expect(_.first(functor.tasks)).toMatchObject(
      type: 'CreateChannel',
      context:
        blueprint:
          network: 'Twitter'
          tags: ['BTCV']
      priority: 10,
      genome: []
    )
    channelIds = []
    for task in functor.tasks when task.type is 'CreateChannel'
      result = await db.Channels.insertOne(Object.assign(
        name: "#{task.context.blueprint.tags[0]} #{task.context.blueprint.network} channel"
      , task.context.blueprint))
      expect(result).toMatchObject({ insertedId: expect.any(Object) })
      channelIds.push(result.insertedId)
    await functor.reexecute()
    expect(_.first(functor.tasks)).toMatchObject(
      type: 'DecorateChannel',
      context:
        channel: expect.objectContaining({
          tags: ['BTCV']
        })
      priority: 10,
      genome: []
    )
    await db.Channels.updateMany({ _id: { $in: channelIds } }, { $set: { isDecorated: true } })
    await functor.reexecute()
    expect(_.first(functor.tasks)).toMatchObject(
      type: 'SendMessage',
      context:
        blueprint:
          channelId: expect.any(Object)
      priority: 10,
      genome: []
    )
    for channelId in channelIds
      messages =
        for i in [1..5]
          {
            channelId: channelId,
            text: "Message for channel #{channelId} with index #{i}",
            author: "@Author",
            context: {}
          }
      await db.Messages.insertMany(messages)
    await functor.reexecute()
    expect(_.first(functor.tasks)).toMatchObject(
      type: 'CreateArtefact',
      context: { description: 'https://workflowy.com/#/17112ae471fc' },
      priority: 10,
      genome: []
    )
    # TODO: add tests for messages

  # Jest requires `describe` callback to return undefined
  return undefined
