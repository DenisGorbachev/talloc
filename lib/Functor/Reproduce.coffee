import _ from 'lodash'
import moment from 'moment'
import Joi from '@hapi/joi'
import Functor from '../Functor'
import GetIncomingTransaction from './GetIncomingTransaction'

export default class Reproduce extends Functor
  constructor: (config) ->
    super(Joi.attempt(config, Joi.object().keys({
      minAmountMonthly: Joi.number().required().min(1),
      months: Joi.number().required().default(3)
    })))
  execute: ->
    from = moment().subtract(months, 'months').toDate()
    transactions = await @db.Transactions.find({createdAt: {$gte: from}, recipientId: @user._id}).fetch()
    # TODO: calculate free monthly amount, not total
    amountMonthly = _.sumBy(transactions, 'amount') / @months
    # TODO: progressively descend into building a new income source
    if amountMonthly > @minAmountMonthly
      return {
        type: 'Reproduce'
        context:
          user: @user
      }
    else
      new GetIncomingTransaction(user: @user).execute()
