//
// Copyright 2022-2024 by garmin@emeska.nl
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

import Toybox.System;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.Time.Gregorian;
import Toybox.Time;

//! Creates a web request on select events, and browse through day, month and year statistics
(:background)
class SolarEdgeAPI extends SolarAPI {
    private var _baseUrl = "https://monitoringapi.solaredge.com/site/";
    private var _startDate = "2022-01-01";

    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as SolarStats or SolarSettings or Array or String or Null) as Void) {
        SolarAPI.initialize(handler);
        getDataPeriod();
    }

    protected function ReadSettings() {
        SolarAPI.ReadSettings();
        //_extended = Properties.getValue($.extended);
    }


    public function getSystem() {
        // not implemented for Solar Edge
    }

    public function getStatus() as Void {
        var url = _baseUrl + _sysid + "/overview";

        var params = {           // set the parameters
            "api_key" => _apikey,
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onReceiveOverview) );
    }

    public function getHistory( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        getPowerDetails( DateTimeString(df), DateTimeString(dt) );
    }

    public function getDayGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        getEnergyDetails("DAY", DateTimeString(df), DateTimeString(dt));
    }

    public function getMonthGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        getEnergyDetails("MONTH", DateTimeString(df), DateTimeString(dt));
    }

    public function getYearGraph( date as Gregorian.Info ) as Void {
        getEnergyDetails("YEAR", _startDate + " 00:00:00", DateTimeString(date));
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


    private function getPowerDetails( tf as String, tt as String ) as Void {
        var url = _baseUrl + _sysid + "/powerDetails";

        var params = {
            "api_key"   => _apikey,
            "startTime" => tf,
            "endTime"   => tt,
            "meters"    => "Production",
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onPowerDetailsResponse) );

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

    //! Query the statistics of the PV System for the specified periods
    private function getEnergyDetails( unit as String, df as String, dt as String) as Void {
        var url = _baseUrl + _sysid + "/energyDetails";

        var params = {
            "api_key"   => _apikey,
            "startTime" => df,
            "endTime"   => dt,
            "timeUnit"  => unit,
            "meters"    => "PRODUCTION,CONSUMPTION"
        };

        var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET
		};

        Communications.makeWebRequest( url, params, options, method(:onEnergyDetailsResponse) );
    }

    //! Receive the data from the web request
    public function onReceiveOverview(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 ) {
            var overview = data.get("overview") as Dictionary;
            var lastUpdate = overview.get("lastUpdateTime") as String;
            
            var currentPower = overview.get("currentPower") as Dictionary;
            var power = currentPower.get("power") as String;
            
            var lastDay = overview.get("lastDayData") as Dictionary;
            var energy = lastDay.get("energy") as String;
            
            var stats = new SolarStats();
            stats.period     = dayStats;
            stats.date       = ParseDateString(lastUpdate);
            stats.time       = ParseTimeString(lastUpdate);
            stats.generated  = energy;
            stats.generating = power;

            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onReceiveDataPeriod(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 ) {
            var dataPeriod = data.get("dataPeriod") as Dictionary;
            _startDate = dataPeriod.get("startDate");
            System.print(_startDate);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onPowerDetailsResponse( responseCode as Number, data as Dictionary or String or Null ) as Void {
        if (responseCode == 200) {
            var powerDetails = data.get("powerDetails") as Dictionary;
            var meters = powerDetails.get("meters") as Array;
            var values = null as Array<Dictionary>;

            for ( var i=0; i<meters.size(); i++ ) {
                if ( meters[i].get("type").equals("Production") ) {
                    values = meters[i].get("values") as Array<Dictionary>;
                }
            }
            
            var stats = [] as Array<SolarStats>;
            for ( var i = values.size()-1; i >= 0; i-- ) {
                if ( System.getSystemStats().freeMemory < 2500 ) {
                    break;
                }
                stats.add(ProcessSitePower(ResponseType(powerDetails.get("timeUnit") as String), values[i]));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onEnergyResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 ) {
            var energy = data.get("energy") as Dictionary;
            var values = energy.get("values") as Array;
            var stats = [] as Array<SolarStats>;
            for ( var i = values.size()-1; i >= 0; i-- ) {
                var period = ResponseType(energy.get("timeUnit") as String);
                if ( values.size() == 31 ) {
                    period = monthStats;
                    if ( i < 31-DayOfMonth(Time.today()) ) {
                        break;
                    }
                }
                stats.add(ProcessSiteEnergy(period, values[i], null));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    //! Receive the data from the web request
    public function onEnergyDetailsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 ) {
            var energy = data.get("energyDetails") as Dictionary;
            var meters = energy.get("meters") as Array;

            var production = null as Array<Dictionary>;
            var consumption = null as Array<Dictionary>;

            for ( var i = 0; i < meters.size(); i++ ) {
                if ( meters[i].get("type").equals("Production") ) {
                    production = meters[i].get("values") as Array<Dictionary>;
                } else if ( meters[i].get("type").equals("Consumption") ) {
                    consumption = meters[i].get("values") as Array;
                }
            }
            
            var stats = [] as Array<SolarStats>;
            for ( var i = production.size()-1; i >= 0; i-- ) {
                var period = ResponseType(energy.get("timeUnit") as String);
                if ( production.size() == 31 ) {
                    period = monthStats;
                    if ( i < 31-DayOfMonth(Time.today()) ) {
                        break;
                    }
                }
                stats.add(ProcessSiteEnergy(period, production[i], consumption != null ? consumption[i] : null));
            }
            _notify.invoke(stats);
        } else {
            ProcessError(responseCode, data);
        }
    }

    private function ProcessSiteEnergy( period as Statistics, production as Dictionary, consumption as Dictionary or Null ) as SolarStats {
        var _stats = new SolarStats();

        _stats.date         = ParseDateString(production.get("date") as String);
        _stats.time         = ParseTimeString(production.get("date") as String);
        _stats.period       = period;
        _stats.generated    = CheckFloat(production.get("value") as Float);
        if ( consumption != null ) {
            _stats.consumed = CheckFloat(consumption.get("value") as Float);
        }

        return _stats;
    }

    private function ProcessSitePower( period as Statistics, values as Dictionary ) as SolarStats {
        var _stats = new SolarStats();

        _stats.date         = ParseDateString(values.get("date") as String);
        _stats.time         = ParseTimeString(values.get("date") as String);
        _stats.period       = period;
        _stats.generating   = CheckFloat(values.get("value") as Float);

        return _stats;
    }

    public function ProcessError( responseCode as Number, data as String ) {
        if ( responseCode == 403 ) {
            _notify.invoke(_unauthorized);
        } else {
            var message = CommunicationsError.Message(responseCode);
            if ( message != null ) {
                _notify.invoke(message);
            } else {
                _notify.invoke(_errormessage + responseCode.toString());
            }
        }
    }

    private function ResponseType( unit as String ) as Statistics {
        var type = unknown;

        if ( unit.equals("QUARTER_OF_AN_HOUR") ) {
            type = currentStats;
        } else if ( unit.equals("DAY") ) {
            type = weekStats;
        } else if ( unit.equals("WEEK") ) {
            type = monthStats;
        } else if ( unit.equals("MONTH") ) {
            type = yearStats;
        } else if ( unit.equals("YEAR") ) {
            type = totalStats;
        }

        return type;
    }

    private function ParseDateString( input as String ) as String {
        return input.substring(0,10);
    }

    private function ParseTimeString( input as String ) as String {
        return input.substring(11,16);
    }

    private function DateTimeString( date as Gregorian.Info ) as String {
        return DateString(date) + " " + TimeString(date);
    }

    protected function DateString( date as Gregorian.Info ) as String {
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
}

//! convert string into a substring array
(:background)
public function ParseString(delimiter as String, data as String) as Array {
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

(:background)
public function CheckLong( value as Long ) as Long {
    if ( value == null ) {
        value = NaN;
    }
    return value;
}

(:background)
public function CheckFloat( value as Float ) as Float {
    if ( value == null ) {
        value = NaN;
    }
    return value;
}

(:background)
public function DayOfMonth( date as Time.Moment ) as Number {
    return Gregorian.info(date, Time.FORMAT_SHORT).day;
    //return 31;
}