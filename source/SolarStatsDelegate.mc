//
// Copyright 2022 by garmin@ibuyonline.nl
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
// associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Properties;
import Toybox.Time.Gregorian;

enum Pages {
    day,        // 0
    hourGraph,  // 1
    dayGraph,   // 2
    monthGraph, // 3
    yearGraph   // 4
}

//! Creates a web request on select events, and browse through day, month and year statistics
(:glance) class SolarStatsDelegate extends WatchUi.BehaviorDelegate {
    private var _sysid = $._sysid_ as Long;
    private var _apikey = $._apikey_ as String;
    private var _notify as Method(args as SolarStats or Array or String or Null) as Void;
    private var _idx = day as Pages;
    private var _baseUrl = "https://monitoringapi.solaredge.com/site/";
    private var _startDate = "2022-01-01";
    private var _connectphone as String;
    private var _errormessage as String;
    private var _unauthorized as String;

    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as SolarStats or Array or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        _notify = handler;
        _connectphone = WatchUi.loadResource($.Rez.Strings.connect) as String;
        _errormessage = WatchUi.loadResource($.Rez.Strings.error) as String;
        _unauthorized = WatchUi.loadResource($.Rez.Strings.unauthorized) as String;

        ReadSettings();
        getDataPeriod();
        getStatus();
    }

    private function ReadSettings() {
        _sysid  = Properties.getValue($.sysid);
        _apikey = Properties.getValue($.api);
    }

    //! On a menu event, make a web request
    //! @return true if handled, false otherwise
    public function onMenu() as Boolean {
        return true;
    }

    //! On a select event, make a web request
    //! @return true if handled, false otherwise
    public function onSelect() as Boolean {

        if ( !System.getDeviceSettings().phoneConnected ) {
            _notify.invoke(_connectphone);
            return false;
        }

        _idx++;
        if ( _idx > yearGraph ) {
            _idx = day;
        }

        var today = DaysAgo(0);
        switch ( _idx ) {
        case day:
            getStatus();
            break;
        case hourGraph:
            getHistory();
            break;
        case dayGraph:
            getDayGraph(DateString(DaysAgo(6)), DateString(today));
            break;
        case monthGraph:
            getMonthGraph(DateString(BeginOfYear(today)), DateString(today));
            break;
        case yearGraph:
            getYearGraph(_startDate, DateString(today));
            break;
        default:
            break;
        }

        return true;
    }

    //! Query the statistics of the PV System for the specified periods
    private function getDataPeriod() as Void {
        var url = _baseUrl + _sysid + "/dataPeriod";

        var params = {           // set the parameters
            "api_key" => _apikey,
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveDataPeriod) );
    }


    //! Query the current status of the PV System
    private function getStatus() as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {           // set the parameters
            "api_key" => _apikey,
            "startTime" => "2022-10-03 11:00:00",
            "endTime" => "2022-10-03 12:00:00",
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        //Communications.makeWebRequest( url, params, options, method(:onReceiveResponse) );
    }

    //! Query the current status of the PV System
    private function getHistory() as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {           // set the parameters
            "api_key" => _apikey,
            "startDate" => "2022-10-01",
            "endDate" => "2022-10-01",
            "timeUnit" => "DAY"
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    private function getDayGraph( df as String, dt as String ) as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {           // set the parameters
            "api_key" => _apikey,
            "startDate" => df,
            "endDate" => dt,
            "timeUnit" => "DAY"
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    private function getMonthGraph( df as String, dt as String ) as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {           // set the parameters
            "api_key" => _apikey,
            "startDate" => df,
            "endDate" => dt,
            "timeUnit" => "MONTH"
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveArrayResponse) );
    }

    //! Query the statistics of the PV System for the specified periods
    private function getYearGraph(df as String, dt as String) as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {           // set the parameters
            "api_key" => _apikey,
            "startDate" => df,
            "endDate" => dt,
            "timeUnit" => "YEAR"
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveArrayResponse) );
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveDataPeriod(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200 ) {
            var dataPeriod = data.get("dataPeriod");
            _startDate = dataPeriod.get("startDate");
        }
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200) {
            System.println(data);
            var energy = data.get("energy");
            var values = energy.get("values");
            var value = values[0].get("value");
            var stats = new SolarStats();
            stats.generated = value;
            stats.date = "2022-10-03";
            stats.time = "21:00";

            //var siteEnergy = data.get('sitesEnergy');
            // var record = ParseString(",", data.toString());
            // var stats = ProcessResult(ResponseType(record), record);
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    //! @param responseCode The server response code
    //! @param data Content from a successful request
    public function onReceiveArrayResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200 ) {
            var energy = data.get("energy");
            var values = energy.get("values");
            var stats = [] as Array<SolarStats>;
            for ( var i = values.size()-1; i >= 0; i-- ) {
                stats.add(ProcessSiteEnergy(ResponseType(energy.get("timeUnit")), values[i]));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    public function ProcessError( responseCode as Number, data as String ) {
        if ( IsPvOutputError(responseCode) ) {
            switch (responseCode) {
            case 401:
                _notify.invoke(_unauthorized);
                break;
            default:
                _notify.invoke("PVOutput - " + data);
            }
        } else {
            var message = CommunicationsError.Message(responseCode);
            if ( message != null ) {
                _notify.invoke(message);
            } else {
                _notify.invoke(_errormessage + responseCode.toString());
            }
        }
    }

    private function IsPvOutputError(errorCode as Number ) as Boolean {
        var isError = false;
        if ( errorCode >= 400 and errorCode < 500 ) {
            isError = true;
        }
        return isError;

    }

    private function ResponseType( unit as String ) as String {
        var type = "n/a";

        if ( unit.equals("DAY") ) {
            type = "week";
        } else if ( unit.equals("MONTH") ) {
            type = "month";
        } else if ( unit.equals("YEAR") ) {
            type = "year";
        }

        return type;
    }

    private function ProcessSiteEnergy( period as String, values as Array ) as SolarStats {
        var _stats = new SolarStats();

        _stats.period       = period;
        _stats.generated    = values.get("value");

        var date = ParseDate( values.get("date") );
        if ( period.equals("week") ) {
            _stats.date = date.day_of_week;
        } else if ( period.equals("month") ) {
            _stats.date = date.month;
        } else if ( period.equals("year") ) {
            _stats.date = date.year.toString();
        } else {
            _stats.date = date;
        }

        return _stats;
    }

    private function ProcessResult( period as String, values as Array ) as SolarStats {
        var _stats = new SolarStats();

        _stats.period       = period;
        _stats.date         = ParseDate(values[0]);

        if ( period.equals("day") ) {
            _stats.time         = values[1];
            _stats.generated    = values[2].toFloat();
            _stats.generating   = values[3].toLong();
            _stats.consumed     = values[4].toFloat();
            _stats.consuming    = values[5].toLong();
        } else if (period.equals("history") ) {
            _stats.time         = values[1];
            _stats.generated    = values[2].toFloat();
            _stats.generating   = values[4].toLong();
            _stats.consumed     = values[7].toFloat();
            _stats.consuming    = values[8].toLong();
        } else if (period.equals("week") ) {
            _stats.time         = values[6];
            _stats.generated    = values[1].toFloat();
            _stats.generating   = NaN;
            _stats.consumed     = values[4].toFloat();
            _stats.consuming    = NaN;
        }
        else {
            _stats.time         = values[1];
            _stats.generated    = values[2].toFloat();
            _stats.generating   = NaN;
            _stats.consumed     = values[5].toFloat();
            _stats.consuming    = NaN;
        }

        return _stats;
    }

    private function Period( idx as Pages ) as String {
        var period = "unknown";
        if ( idx == day ) {
            period = "day";
        } else if ( idx == hourGraph ) {
            period = "history";
        } else if ( idx == dayGraph ) {
            period = "week";
        } else if ( idx == monthGraph ) {
            period = "month";
        } else if ( idx == yearGraph ) {
            period = "year";
        }

        return period;
    }

    private function ParseDate( input as String ) as String {
        return DateInfo(input.substring(0,4), input.substring(5,7), input.substring(8,10));
    }

    private function DateInfo( year as String, month as String, day as String ) as Gregorian.Info {
        var options = {
            :year => year.toNumber(),
            :month => month.toNumber(),
            :day => day.toNumber(),
            :hour => 0,
            :minute => 0
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_LONG);
    }

    private function DaysAgo( days_ago as Number ) as Gregorian.Info {
        var today = new Time.Moment(Time.today().value());
        return Gregorian.info(today.subtract(new Time.Duration(days_ago*60*60*24)), Time.FORMAT_SHORT);
    }

    private function BeginOfMonth( date as Gregorian.Info ) as Gregorian.Info {
        var options = {
            :year => date.year,
            :month => date.month,
            :day => 1
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_SHORT);
    }

    private function BeginOfYear( date as Gregorian.Info ) as Gregorian.Info {
        var options = {
            :year => date.year,
            :month => 1,
            :day => 1
        };
        return Gregorian.info(Gregorian.moment(options), Time.FORMAT_SHORT);
    }

    private function DateString( date as Gregorian.Info ) as String {
        return Lang.format(
            "$1$-$2$-$3$",
            [
                date.year,
                date.month.format("%02d"),
                date.day.format("%02d")
            ]
        );
    }

    //! convert string into a substring dictionary
    private function ParseString(delimiter as String, data as String) as Array {
        var result = [] as Array<String>;
        var endIndex = 0;
        var subString;
        
        while (endIndex != null) {
            endIndex = data.find(delimiter);
            if ( endIndex != null ) {
                subString = data.substring(0, endIndex) as String;
                data = data.substring(endIndex+1, data.length());
            } else {
                subString = data;
            }
            result.add(subString);
        }

        return result;
    }
}