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
            var moment = new Time.Moment(Time.now().value());
            var now = Gregorian.info(moment,Time.FORMAT_SHORT );
            getPower( DateTimeString(today), DateTimeString(now) );
            break;
        case dayGraph:
            getEnergy( "DAY", DateString(DaysAgo(6)), DateString(today) );
            break;
        case monthGraph:
            getEnergy( "MONTH", DateString(BeginOfYear(today)), DateString(today));
            break;
        case yearGraph:
            getEnergy( "YEAR", _startDate, DateString(today) );
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

    private function getPower( tf as String, tt as String ) as Void {
        var url = _baseUrl + _sysid + "/powerDetails";

        var params = {
            "api_key"   => _apikey,
            "startTime" => tf,
            "endTime"   => tt,
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onPowerResponse) );

    }

    //! Query the statistics of the PV System for the specified periods
    private function getEnergy( unit as String, df as String, dt as String) as Void {
        var url = _baseUrl + _sysid + "/energy";

        var params = {
            "api_key"   => _apikey,
            "startDate" => df,
            "endDate"   => dt,
            "timeUnit"  => unit
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onEnergyResponse) );
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
    public function onReceiveResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200) {
            var energy = data.get("energy");
            var values = energy.get("values");
            var value = values[0].get("value");
            var stats = new SolarStats();
            stats.generated = value;
            stats.date = "2022-10-03";
            stats.time = "21:00";

            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onPowerResponse( responseCode as Number, data as Dictionary<String, Object?> or String or Null ) as Void {
        if (responseCode == 200) {
            var powerDetails = data.get("powerDetails");
            var meters = powerDetails.get("meters");
            var values = meters[0].get("values");
            var stats = [] as Array<SolarStats>;
            for ( var i = values.size()-1; i >= 0; i-- ) {
                stats.add(ProcessSitePower(ResponseType(powerDetails.get("timeUnit")), values[i]));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onEnergyResponse(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        System.println(data);
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

        if ( unit.equals("QUARTER_OF_AN_HOUR") ) {
            type = "history";
        } else if ( unit.equals("DAY") ) {
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

        var date = Gregorian.info(ParseDate(values.get("date")), Time.FORMAT_LONG);
        if ( period.equals("week") ) {
            _stats.date = date.day_of_week;
        } else if ( period.equals("month") ) {
            _stats.date = date.month;
        } else if ( period.equals("year") ) {
            _stats.date = date.year.toString();
        } else {
            _stats.date = date;
        }
        _stats.time = TimeString(date);

        return _stats;
    }

    private function ProcessSitePower( period as String, values as Array ) as SolarStats {
        var _stats = new SolarStats();

        var date = Gregorian.info( ParseDate(values.get("date")), Time.FORMAT_SHORT );
        _stats.date         = DateString(date);
        _stats.time         = TimeString(date);

        _stats.period       = period;
        _stats.generating   = values.get("value");

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

    private function ParseDate( input as String ) as Time.Moment {
        return DateInfo(input.substring(0,4), input.substring(5,7), input.substring(8,10), input.substring(11,13), input.substring(14,16));
    }

    private function DateInfo( year as String, month as String, day as String, hour as String, minute as String ) as Gregorian.Moment {
        var options = {
            :year => year.toNumber(),
            :month => month.toNumber(),
            :day => day.toNumber(),
            :hour => hour.toNumber(),
            :minute => minute.toNumber()
        };
        return Gregorian.moment(options);
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

    private function TimeString( date as Gregorian.Info ) as String {
        return Lang.format(
            "$1$:$2$:00",
            [
                date.hour.format("%02d"),
                date.min.format("%02d")
            ]
        );
    }

    private function DateTimeString( date as Gregorian.Info ) as String {
        return DateString(date) + " " + TimeString(date);
    }
}