import _ from 'lodash'
import moment from 'moment'
import Joi from '@hapi/joi'
import Functor from '../Functor'
#import GetIncomingTransaction from './GetIncomingTransaction'

###
  * Inputs
    * Channels
      * Each
        * Is decorated
        * Has posts
      * All
        * Are related to the same project
    * Token
      * Has use case
      * + Has existing market
  * Outputs
    * Channels with higher follower count
    * Persons
      * Has contacts
###
export default class PerformAirdrop extends Functor
  constructor: (opts, deps) ->
    super(Joi.attempt(opts, Joi.object().keys({
      projectUid: Joi.string().required(),
      networks: Joi.array().default(['Twitter', 'Facebook', 'Telegram', 'Discord']).items(Joi.string().required()).required(),
      assetUid: Joi.string().required(),
      amount: Joi.number(### per single claim ###).required(),
      limit: Joi.number(### max count of claims ###).required(),
      from: Joi.date(### airdrop start ###).required(),
      to: Joi.date(### airdrop end ###).required(),
      referralLimit: Joi.number(### how many entries can a single person refer ###).default(100).required(),
    })), deps)
  execute: ->
    project = @db.Projects.findOne(uid: @projectUid)
    asset = @db.Assets.findOne(uid: @projectUid)
    spec = await @ensureSpec()
    channels = await @ensureChannels()
    token = await @ensureToken()
    @addText('Determine token amount for airdrop')
    @addText('Evaluate https://gleam.io/ as potential platform')
    @addText('Evaluate whether 10:1 entry:token conversion is necessary')
    @addText('Upvote on each airdrop channel that supports it')
    @addText('Implement account-less upvoting on airdrops.io')
    ###
      * Enough to trigger attention
      * Capped to trigger FOMO
      * Capped to limit our investment
      * May split into multiple rounds to increase conversion
    ###
    # TODO: check that all inputs are present
    # TODO: sign agreements with airdrop announcement channels
    # TODO: ping them again if they don't respond
    message = @buildMessageForAirdropRecipients(project, asset)
    @sendMessagesToAirdropFeeds()
  ensureSpec: ->
    assetUid: @assetUid
    amount: @amount
  ensureChannels: ->
    channels = await @db.Channels.find({tags: @projectUid}).toArray()
    for network in @networks
      channel = _.find(channels, {network})
      if !channel
        @add('CreateChannel',
          blueprint:
            network: network,
            tags: [@projectUid]
        )
    channels
  ensureToken: ->
    transactions = await @db.Transactions.find({asset: @asset}).toArray()
    sum = _.sumBy(transactions, (transaction) -> if transaction.isIncoming then transaction.amount else -1 * transaction.amount);
  buildMessageForAirdropRecipients: (project, asset) ->
    """
      #{project.description}

      #{project.name} is airdropping free #{@asset.uid} tokens to their community members. Sign up at their airdrop page, complete easy tasks and submit your details to the airdrop page to receive free entries. Also, earn up to #{@referralLimit} entries by inviting your friends. Entries will be converted to #{@asset.uid} token in the ratio of 10:1. The airdrop ends at #{@to}.
    """
  sendMessagesToAirdropFeeds: ->
    channels = await @db.Channels.find({tags: 'Airdrop'}).toArray()
