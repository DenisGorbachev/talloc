import _ from 'lodash'
import moment from 'moment'
import {MongoClient} from 'mongodb'
import PerformAirdrop from '../lib/Functor/PerformAirdrop'

describe 'PerformAirdrop', ->
  connection = null
  db = null

  beforeAll ->
    connection = await MongoClient.connect(global.__MONGO_URI__, {useNewUrlParser: true})
    db = await connection.db(global.__MONGO_DB_NAME__)
    db.Users = db.collection('Users')
    db.Projects = db.collection('Projects')
    db.Channels = db.collection('Channels')
    db.Artefacts = db.collection('Artefacts')
    db.Assets = db.collection('Assets')
    db.Transactions = db.collection('Transactions')

  afterAll ->
    await connection.close()
    await db.close()

  it 'should return the task for denis.d.gorbachev@gmail.com', ->
    await db.Assets.insertOne(
      uid: 'BTCV',
      maxSupply: 100000000,
      circulatingSupply: 9117300,
      # price in USD
      price: 0.03
    )
    functor = new PerformAirdrop({
      projectUid: 'BTCV',
      networks: ['Twitter', 'Facebook', 'Telegram', 'Discord']
      assetUid: 'MOON',
      amount: 10000,
      limit: 1000,
      from: new Date('2019-07-22'),
      to: new Date('2019-07-31'),
      referralLimit: 100,
    }, {db})
    await functor.execute()
    expect(functor.tasks).toBe([
      {
        type: 'CreateChannel',
        context:
          blueprint:
            network: 'Telegram'
      }
    ])

  # Jest requires `describe` callback to return undefined
  return undefined
