window.rizzomaNotifications = window.rizzomaNotifications || {}

_expressSessionId = null
_lastTimeOfGettingAuthId = null

intervalForPerformanceMeasureInMinutes = 10

askForNewMentionsAndDisplay = ->
    window.rizzomaNotifications.askForNewMentions(
        (data) ->
                countUnreadMentionsAndDisplay(data.data)
    )

makePerformanceTest = ->
    if (userIsLoggedIn())
        # should get: all results, most reults, some results, no results
        queryStrings = ["", "and", "local", "nac", "nat", "nonexistingword"]
        makeSearchRequestsAndStoreDurations(queryStrings)
    
userIsLoggedIn = ->
    return _expressSessionId != null

makeSearchRequestsAndStoreDurations = (queryStrings) ->
    if (queryStrings? and queryStrings.length > 0)
        console.log("making search requests....")
        timeBefore = Date.now()
        queryString = queryStrings[0]
        remainingQueryStrings = queryStrings[1..]
        makeSearchRequest(queryString, 
            storeRequestAndContinue.bind(this, queryString, timeBefore, remainingQueryStrings))

storeRequestAndContinue = (queryString, timeBefore, remainingQueryStrings, answer) ->
    searchingWorked = answer.data.lastSearchDate? # if searching doesnt work, this property does not exist :)
    if (searchingWorked)
      timeNow = Date.now()
      requestDuration = timeNow - timeBefore
      measurement = {
          type: "search",
          queryString: queryString,
          timeNow: timeNow,
          requestDuration: requestDuration
      }
      console.log("got result....", answer)
      storeMeasurement(measurement)
      makeSearchRequestsAndStoreDurations(remainingQueryStrings)
    else if (timeSinceGettingAuthIdLongEnough())
      console.log ("searching didn't work mit #{_expressSessionId}, reinserting iframe")
      reinsertRizzomaIFrameForGettingAuthId()

storeMeasurement = (measurement) ->
    measurements = []
    # look if there were measurements at this time before, if yes, keep them as well
    if (localStorage[measurement.timeNow])
        earlierMeasurements = JSON.parse(localStorage[measurement.timeNow])
        measurements = measurements.concat(earlierMeasurements)
    measurements.push(measurement)
    localStorage[measurement.timeNow] = JSON.stringify(measurements)

makeSearchRequest = (queryString, callback) ->
    $.ajax(
        {
            url: "https://rizzoma.com/api/rest/1/wave/searchBlipContent/",
            data: {
                queryString: queryString,
                lastSearchDate: 0,
                ACCESS_TOKEN: _expressSessionId
            },
            dataType: 'json',
            success: callback
        }
    )

timeSinceGettingAuthIdLongEnough = ->
  minutesToWait = 20
  minutesSinceGettingAuthId = (Date.now() - _lastTimeOfGettingAuthId) / (1000 * 60) # convert from ms to minutes
  return minutesSinceGettingAuthId > minutesToWait 

reinsertRizzomaIFrameForGettingAuthId = ->
  $('body').append('<iframe src="https://rizzoma.com/topic/" id="rizzomaPerformanceIFrame"></iframe>')
    
handleExpressSessionId = (expressSessionIdMessage) ->
  # expresssession id is part of message after "HAVE_EXPRESS_SESSION_ID: "
  _expressSessionId = expressSessionIdMessage["HAVE_EXPRESS_SESSION_ID: ".length..]
  _lastTimeOfGettingAuthId = Date.now()
  removeRizzomaIFrame()
  makePerformanceTest()
  setInterval(makePerformanceTest, intervalForPerformanceMeasureInMinutes * 60 * 1000)

removeRizzomaIFrame = ->
    $('#rizzomaPerformanceIFrame').remove()

chrome.extension.onMessage.addListener((messageString, sender, sendResponse) ->
    if (messageString[0..."HAVE_EXPRESS_SESSION_ID: ".length] == "HAVE_EXPRESS_SESSION_ID: ")
        handleExpressSessionId(messageString)     
    return true # has to be done for other messages to be handlable by other listeners
)

