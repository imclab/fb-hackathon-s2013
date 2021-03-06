Event = require '../../models/event'
Response = require '../../models/response'
dates = require '../../helpers/dates'
Ranking = require 'smart-ranking'

# Event model's CRUD controller.
module.exports =

  # Lists all events
  index: (req, res) ->
    Event.find {}, (err, events) ->
      res.send events

  # Creates new event with data from `req.body`
  create: (req, res) ->
    event = new Event req.body

    event.dates = event.dates.map (date) ->
      dates.normalize date

    event.save (err, event) ->
      if not err
        res.send event
        res.statusCode = 201
      else
        res.send err
        res.statusCode = 500

  createResponse: (req, res) ->
    response = new Response req.body

    response.save (err, saved) ->
      Event
        .findById(req.params.id)
        .populate('responses')
        .populate('invited')
        .exec (err, event) ->
          event.responses.push saved

          event.save (err, update) ->
            if not err
              res.send update
            else
              res.send 500, err

  # Gets event by id
  get: (req, res) ->
    Event
    .findById(req.params.id)
    .populate('responses')
    .populate('invited')
    .exec (err, event) ->
      if not err
        res.send event
      else
        res.send err
        res.statusCode = 500

  # Updates event with data from `req.body`
  update: (req, res) ->
    Event.findByIdAndUpdate req.params.id, {"$set":req.body}, (err, event) ->
      if not err
        res.send event
      else
        res.send err
        res.statusCode = 500

  # Deletes event by id
  delete: (req, res) ->
    Event.findByIdAndRemove req.params.id, (err) ->
      if not err
        res.send {}
      else
        res.send err
        res.statusCode = 500

  ranking: (req, res) ->
    Event
    .findById(req.params.id)
    .populate('responses')
    .populate('invited')
    .exec (err, event) ->
      locations = event.locations
      ratings = []
      for loc in locations
        ranking_data = {votes: [], id: loc}
        for response in event.responses
          res_locs = response.locations
          index = res_locs.indexOf loc
          index = res_locs.length - index
          ranking_data.votes.push index
        ratings.push ranking_data
      locs_score = Ranking.amazon ratings
      delete locs_score["_avgRatings"]
      delete locs_score["_avgVotes"]
      locs_score = (v for k, v of locs_score)
      locs_score.sort (a,b) -> b.score - a.score
      res.send (x._id for x in locs_score)
