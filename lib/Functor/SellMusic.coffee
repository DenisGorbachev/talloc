import _ from 'lodash'
import moment from 'moment'
import Joi from '@hapi/joi'
import Functor from '../Functor'
#import GetIncomingTransaction from './GetIncomingTransaction'

# Project name: Beathoven
export default class SellMusic extends Functor
  constructor: (opts, deps) ->
    super(Joi.attempt(opts, Joi.object().keys({
#      projectUid: Joi.string(### ###).required(),
    })), deps)
  execute: ->
    # NOTE: http://money.futureofmusic.org/revenue-streams-existing-expanded-new + http://money.futureofmusic.org/40-revenue-streams
    # NOTE: Revenue distribution highly favors top artists (https://www.ft.com/content/795fc3e7-52ce-390d-b245-aaeda4f878ce), so our best chance is to sell production music, along with sheets and ringtones
    # tips: https://blog.songtrust.com/songwriting-tips/songwriter-tips-2-how-to-get-sync-placements
    sources = [
      'https://beta.aiva.ai/',
      # Very diverse
      'https://ecrettmusic.com/'
      # Melodic tracks
      # Too much repetition
    ]
    catalogsOfLibraries = [
      'https://musiclibraryreport.com/category/1-to/'
    ]
    libraries = [
      'https://www.shutterstock.com/music/',
      'https://www.premiumbeat.com/',
      'https://www.audionetwork.com/',
      'https://www.productiontrax.com/',
      'https://www.themusicase.com/',
      'https://www.pond5.com/'
    ]
    @addText('Sell to listeners via https://www.tunecore.com/')
    @addText('Sell to product makers via https://www.fiverr.com/categories/music-audio/producers-composers')
    @addText('Sell to product makers (games, podcasts, movies, clips)')
    @addText('Sell to composers')
    @addText('Sell to performers via https://musicspoke.com/')
    @addText("Sell to product makers via music libraries: #{libraries.join(', ')}")
  validateCompositions: ->
    # https://blog.songtrust.com/songwriting-tips/songwriter-tips-2-how-to-get-sync-placements
    @addText('Ensure matches https://musiclibraryreport.com/forums/topic/why-music-tracks-get-rejected/')
    @addText('Ensure file has tags')
    @addText('Ensure file has contacts')
    @addText('Ensure file has email in name')
