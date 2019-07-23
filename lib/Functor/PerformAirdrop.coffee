import util from 'util'
import _ from 'lodash'
import moment from 'moment'
import Joi from '@hapi/joi'
import Functor from '../Functor'
#import GetIncomingTransaction from './GetIncomingTransaction'
import { validateSalesMessage } from '../validators'
import { toMarkdownList, IMNetworks } from '../helpers'

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
    # TODO: sign agreements with airdrop announcement channels
    # TODO: ping them again if they don't respond
    message = await @buildMessageForAirdropRecipients(project, asset)
    await @sendMessagesToAirdropFeeds(project, asset, amount)
    @addText('Upvote on each airdrop channel that supports it')
    @addText('Implement account-less upvoting on airdrops.io')
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
    app = await @db.Artefacts.findOne({ tags: { $all: ['ClaimAirdropApp'] } })
    if !app
      @add('CreateArtefact',
        blueprint:
          name: 'Airdrop application',
          tags: ['ClaimAirdropApp']
        description: 'https://workflowy.com/#/17112ae471fc'
      )
  buildMessageForAirdropRecipients: (project, asset) ->
    """
      #{project.description}

      #{project.name} is airdropping free #{asset.uid} tokens to their community members. Sign up at their airdrop page, complete easy tasks and submit your details to the airdrop page to receive free entries. Also, earn up to #{@referralLimit} entries by inviting your friends. Entries will be converted to #{asset.uid} token in the ratio of 10:1. The airdrop ends at #{@to}.
    """
  sendMessagesToAirdropFeeds: (project, asset, amount) ->
    # TODO: convert Markdown message into HTML for channels that support email
    channels = await @db.Channels.find({ tags: 'Airdrop' }).toArray()
    for channel in channels
      information = "Hi, we're launching an airdrop for #{project.name}"
      motivation = "Looking forward to the day when bounty hunters tell their friends that they got #{asset.uid} airdrop on #{channel.name} ;)"
      action = (
        switch channel.network
          when "Website"
            "add it to #{channel.name}"
          else
            "post it on #{channel.name}"
      )
      guide = "could you please #{action}"
      fears = [
        'Fears losing reputation among bounty hunters for listing low-value airdrops (status)'
        'Fears losing reputation among bounty hunters for listing scam projects (status)'
      ]
      assurances = [
        {
          text: "#{@assetUid} is already listed on Voltex (https://exchange.volatility-tokens.com/)"
          fears: ['Fears losing reputation among bounty hunters for listing low-value airdrops (status)']
        }
        {
          text: "#{project.name} code is already available on GitHub: $link"
          fears: ['Fears losing reputation among bounty hunters for listing scam projects (status)']
        }
      ]
      useCase = "#{asset.uid} provides 30% discount for buying BTCV on Voltex (https://exchange.volatility-tokens.com/)"
      validateSalesMessage(information, motivation, fears, assurances, guide)
      text = """
      #{information} - #{guide}? Here's a full specification:

      * Website: #{project.url}
      * Token: #{asset.uid}
      * Token use case: #{useCase}
      * Amount for one claim: #{amount} #{asset.uid}
      * Max claims: #{@limit}
      * Start date: #{@from}
      * End date: #{@to}

      Extra information:
      #{toMarkdownList(_.map(assurances, 'text'))}

      #{motivation}
      """.trim()
      writerPersonIds = _(channel.permissions).filter({ type: 'private', update: true }).map('personIds').flatten().uniq().value()
      if !writerPersonIds.length
        # TODO: how to update the task if the channel name changes?
        @add('CreateChannelOwner',
          blueprint: {}
          channel: channel
        )
        return
      writerChannels = await @db.Channels.find(
        tags: ['Listing']
        $and: [
          { permissions: { $elemMatch: { type: 'public', create: true } } }
          { permissions: { $elemMatch: { type: 'private', read: true, personIds: { $in: writerPersonIds } } } }
        ]
      ).toArray()
#      console.log('@db.Channels.find().toArray()', util.inspect(await @db.Channels.find().toArray(), { showHidden: false, depth: null }));
#      console.log('writerChannels', writerChannels);
      if !writerChannels.length
        writer = await @db.Persons.findOne({ _id: { $in: writerPersonIds } }, { sort: { createdAt: 1, _id: 1 } })
        # TODO: how to update the task if the channel name changes?
        @add('CreatePrivateChannelWithOwner',
          blueprint: {}
          person: writer
        )
        return
      # TODO: should we message everybody in round-robin fashion?
      # TODO: what if some writers are subscribed to the channels that we've already sent messages through?
      preferredNetworks = ['Phone'].concat(IMNetworks).concat(['Email', 'ContactForm'])
      preferredNetworks.reverse() # for correct sorting
      writerChannels = _.sortBy(writerChannels, (channel) -> preferredNetworks.indexOf(channel.network)).reverse()
      writerChannel = _.first(writerChannels)
      message = await @db.Messages.findOne(
        channelId: writerChannel._id
      )
      if !message
        @add('SendMessage'
          blueprint:
            text: text,
            channel: writerChannel
        )
      if message && message.createdAt < moment().subtract(2, 'days')
        @addText('Build message cadence')
