import _ from 'lodash'
import moment from 'moment'
import Joi from '@hapi/joi'
import Functor from '../Functor'
#import GetIncomingTransaction from './GetIncomingTransaction'
import { validateSalesMessage } from '../validators'
import { toMarkdownList } from '../helpers'

###
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
    project = await @db.Projects.findOne(uid: @projectUid)
    asset = await @db.Assets.findOne(uid: @assetUid)
    amount = @calculateAmount(asset)
    return if !amount
    spec = await @ensureSpec()
    channels = await @ensureChannels()
    token = await @ensureToken()
    app = await @ensureApp()
    @addText('Upvote on each airdrop channel that supports it')
    @addText('Implement account-less upvoting on airdrops.io')
    # TODO: check that all inputs are present
    # TODO: sign agreements with airdrop announcement channels
    # TODO: ping them again if they don't respond
    message = @buildMessageForAirdropRecipients(project, asset)
    @sendMessagesToAirdropFeeds(project, asset)
  calculateAmount: (asset) ->
    # minimum value to get the bounty hunters interested (current range as of 2019-07-21 is 1-10 USD)
    value = 5.0 # USD
    price = asset.lastTradePrice || asset.initialOfferingPrice
    if !price
      @add('SetField',
        collection: 'Assets',
        _id: asset._id,
        field: 'initialOfferingPrice'
      )
      return null
    return value / price
  ensureSpec: ->
    assetUid: @assetUid
    amount: @amount
  ensureChannels: ->
    channels = await @db.Channels.find({ tags: @projectUid }).toArray()
    for network in @networks
      channel = _.find(channels, { network })
      if !channel
        @add('CreateChannel',
          blueprint:
            network: network,
            tags: [@projectUid]
        )
    for channel in channels
      if !channel.isDecorated
        @add('DecorateChannel',
          channel: channel
        )
      messagesCount = await @db.Messages.find({ channelId: channel._id }).count()
      if messagesCount < 5
        @add('SendMessage',
          blueprint:
            channelId: channel._id
        )
    channels
  ensureToken: ->
    transactions = await @db.Transactions.find({ asset: @asset }).toArray()
    sum = _.sumBy(transactions, (transaction) -> if transaction.isIncoming then transaction.amount else -1 * transaction.amount);
  ensureApp: ->
    # @addText('Evaluate https://gleam.io/ as potential platform')
    app = await @db.Artefacts.findOne({ tags: { $all: ['Airdrop', 'App'] } })
    if !app
      @add('Execute',
        text: """[Implement airdrop application](https://workflowy.com/#/17112ae471fc)"""
      )
  buildMessageForAirdropRecipients: (project, asset) ->
    """
      #{project.description}

      #{project.name} is airdropping free #{asset.uid} tokens to their community members. Sign up at their airdrop page, complete easy tasks and submit your details to the airdrop page to receive free entries. Also, earn up to #{@referralLimit} entries by inviting your friends. Entries will be converted to #{asset.uid} token in the ratio of 10:1. The airdrop ends at #{@to}.
    """
  sendMessagesToAirdropFeeds: (project, asset) ->
    # TODO: convert Markdown message into HTML for channels that support email
    channels = await @db.Channels.find({ tags: 'Airdrop' }).toArray()
    for channel in channels
      information = "Hi, we're launching an airdrop for #{project.name} (#{project.url})"
      motivation = ""
      action = (
        switch channel.network
          when "Website"
            "add it to #{channel.name}"
          else
            "post it on #{channel.name}"
      )
      guide = "could you please #{action}"
      validateSalesMessage(information, motivation, fears, assurances, guide)
      message = """
      #{information} - #{guide}? Here's a full specification:

      #{}
      """.trim()
      @addText('Build cadence (if messages were left unanswered)')
      # NOTE: we have multiple contacts (including website form)
      # NOTE: we generally don't know how many people are running the show
