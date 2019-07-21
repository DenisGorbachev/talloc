import _ from 'lodash'
import { joi } from './helpers'

###
  Bananas have recently appeared in all 7-Elevens across Koh-Phangan.

  You can satisfy your hunger by eating bananas between meals.

  * Bananas are cheap.
  * Bananas are healthier than other snacks.

  Find a nearest 7-Eleven with bananas: $url
###
export validateSalesMessage = (information, motivation, fears, assurances, guide) ->
  joi.attempt(information, joi.string())
  joi.attempt(motivation, joi.string())
  joi.attempt(fears, joi.array().items(joi.string()))
  joi.attempt(assurances, joi.object().pattern(/.*/, [joi.string()]))
  joi.attempt(guide, joi.string())
  assuranceKeys = _.keys(assurances)
  assuranceValues = _.values(assurances)
  for fear in fears
    if !fear.matches(fearRegExp)
      throw new Error("Fear '#{fear}' should match RegExp #{fearRegExp}")
  if !_.isEqual(assuranceKeys, fears)
    throw new Error('Message should relieve the fears of recipient')
#  """
#    #{information}
#
#    #{motivation}
#
#    #{assuranceValues.map((v) -> '* ' + v).join('\n')}
#
#    #{guide}
#  """

###
  Fears losing health
    Fears losing life
    Fears losing limbs / organs
    Fears losing sanity
  Fears losing wealth
    Fears losing personal money
    Fears losing investor money ~ Fears losing respect of investors
  Fears losing status
    Fears losing power over subordinates
    Fears losing appreciation of peers
  Fears losing time
    Fears losing time on unimportant deeds
    Fears losing time on projects that go nowhere
  Fears losing freedom
    Fears losing ability to move
    Fears losing ability to make decisions
###
export fearRegExp = new RegExp('^Fears losing.*\\((?:health|wealth|status|time|freedom)\\)$', 'g')
