displayAllMeasurements = ->
    #todo: just extract all searchwords from all measurements?...
   for searchWord in ["", "and", "local", "nat", "nonexistingword"]
        displayMeasurementsForWord(searchWord)

displayMeasurementsForWord = (searchWord) ->
    measurements = getAllMeasurementsForWord(searchWord)
    measurementsByHour = groupMeasurementsByHour(measurements)
    mediansByHour = getMediansForEveryHour(measurementsByHour)
    displayMeasurementMediansForWord(searchWord, mediansByHour)

getAllMeasurementsForWord = (searchWord) ->
    measurements = []
    for own time, measurementStrings of localStorage
        measurementsThisTime = JSON.parse(measurementStrings)
        for measurement in measurementsThisTime
            if measurement.queryString == searchWord
                measurements.push(measurement)
    return measurements

groupMeasurementsByHour = (measurements) ->
    measurementsByHour = {}
    for hour in [0..23]
        measurementsThisHour = measurements.filter((measurement) ->
            new Date(measurement.timeNow).getUTCHours() == hour)
        measurementsThisHour = measurementsThisHour.map((measurement) ->
          return measurement.requestDuration)
        measurementsByHour[hour] = measurementsThisHour

getMediansForEveryHour = (measurementsByHour) ->
  mediansByHour = {}
  for own hour, measurements of measurementsByHour
    # sort numerically
    measurements.sort((durationA, durationB) ->
      return durationA - durationB)
    median = measurements[Math.floor(measurements.length / 2)]
    mediansByHour[hour] = median
  return mediansByHour

displayMeasurementMediansForWord = (searchWord, mediansByHour) ->
  addTableColumn(searchWord)
  for hour in [0..24]
    addMeasurementToTable(hour, mediansByHour[hour])

addTableColumn = (searchWord) ->
  # add seachword as heading to table
  $('#measurementTable thead tr').append("<th>#{searchWord}</th>")

addMeasurementToTable = (hour, median) ->
  # find correct table row for correct hour and append table cell with
  # new measurement
  medianString = if median? then median else "X"
  $("#measurementTable tbody tr").eq(hour).append("<td>#{medianString}</td>")

displayAllMeasurements()