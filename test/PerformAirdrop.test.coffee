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

  afterAll ->
    await connection.close()
    await db.close()

  it 'should return the task for denis.d.gorbachev@gmail.com', ->
    await db.Assets.insert(
      symbol: 'BTCV',
      maxSupply: 100000000,
      circulatingSupply: 9117300,
      # price in USD
      price: 0.03
    )
    functor = new PerformAirdrop({
      project: 'BTCV',
      asset: 'BTCV',
      amount: 10000,
      networks: ['Twitter', 'Facebook', 'Telegram', 'Discord']
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

  # Jest requires `describe` callback not to return any value
  return undefined
