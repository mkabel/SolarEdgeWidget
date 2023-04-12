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
import Toybox.Application.Properties;
import Toybox.Time.Gregorian;

(:background)
enum  Statistics {
    unknown,      // 0
    currentStats, // 1
    dayStats,     // 2
    weekStats,    // 3
    monthStats,   // 4
    yearStats     // 5
}

(:background)
class SolarAPI {
    protected var _notify as Method(args as SolarStats or Array or String or Null) as Void;
    protected var _sysid = $._sysid_ as Long;
    protected var _apikey = $._apikey_ as String;
    protected var _errormessage = "ERROR" as String;
    protected var _unauthorized = "UNAUTHORIZED" as String;

    hidden function initialize( handler as Method(args as SolarStats or Array or String or Null) as Void ) {
        _notify = handler;

        _errormessage = Application.loadResource($.Rez.Strings.error) as String;
        _unauthorized = Application.loadResource($.Rez.Strings.unauthorized) as String;

        ReadSettings();
    }

    private function ReadSettings() {
        _sysid  = Properties.getValue($.sysid);
        _apikey = Properties.getValue($.api);
    }

    public function getStatus() as Void {
        throw new Lang.Exception();
    }

    public function getHistory( date as Gregorian.Info ) as Void {
        throw new Lang.Exception();
    }

    public function getDayGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        throw new Lang.Exception();
    }

    public function getMonthGraph( df as Gregorian.Info, dt as Gregorian.Info ) as Void {
        throw new Lang.Exception();
    }

    public function getYearGraph( dt as Gregorian.Info ) as Void {
        throw new Lang.Exception();
    }

    protected function DateString( date as Gregorian.Info ) as String {
        throw new Lang.Exception();
    }

}