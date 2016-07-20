Transaction = require('../model/transactions').Transaction
Channel = require('../model/channels').Channel
moment = require 'moment'
logger = require 'winston'
mongoose = require 'mongoose'
authorisation = require './authorisation'
Q = require 'q'
metrics = require "../metrics"

# all in one getMetrics generator function for metrics API
exports.getMetrics = (groupChannels, timeSeries, channelID) ->
  logger.debug "Called getMetrics(#{groupChannels}, #{timeSeries}, #{channelID})"
  channels = yield authorisation.getUserViewableChannels this.authenticated
  channelIDs = channels.map (c) -> return c._id
  if typeof channelID is 'string' and not (channelID in (channelIDs.map (id) -> id.toString()) )
    this.status = 401
    return
  else if typeof channelID is 'string'
    channelIDs = [mongoose.Types.ObjectId(channelID)]

  query = this.request.query
  logger.debug "Metrics query object: #{JSON.stringify query}"
  startDate = query.startDate
  delete query.startDate
  endDate = query.endDate
  delete query.endDate

  if Object.keys(query).length is 0
    query = null

  m = yield metrics.calculateMetrics new Date(startDate), new Date(endDate), query, channelIDs, timeSeries, groupChannels

  if m[0]?._id?.year? # if there are time components
    m = m.map (item) ->
      item.timestamp = moment(item._id)
      return item

  this.body = m
