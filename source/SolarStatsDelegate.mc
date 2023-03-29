//
// Copyright 2022-2023 by garmin@ibuyonline.nl
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
import Toybox.WatchUi;
import Toybox.Time.Gregorian;

enum Pages {
    day,        // 0
    hourGraph,  // 1
    dayGraph,   // 2
    monthGraph, // 3
    yearGraph   // 4
}

//! Creates a web request on select events, and browse through day, month and year statistics
class SolarStatsDelegate extends WatchUi.BehaviorDelegate {
    private var _notify as Method(args as SolarStats or Array or String or Null) as Void;
    private var _idx = day as Pages;
    private var _connectphone as String;
    private var _api as SolarAPI;
   
    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as SolarStats or Array or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        _notify = handler;

        _connectphone = WatchUi.loadResource($.Rez.Strings.connect) as String;

        _api = new SolarEdgeAPI(handler);
        _api.getStatus();
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
            _api.getStatus();
            break;
        case hourGraph:
            _api.getHistory(today);
            break;
        case dayGraph:
            _api.getDayGraph(DaysAgo(6), today);
            break;
        case monthGraph:
            _api.getMonthGraph(BeginOfYear(today), today);
            break;
        case yearGraph:
            _api.getYearGraph(today);
            break;
        default:
            break;
        }

        return true;
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
}