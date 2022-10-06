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

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Math;
import Toybox.Time.Gregorian;

enum GraphTypes {
    lineGraph,
    barGraph
}

//! Shows the PVOutput Solar panel results
(:glance) class SolarStatsView extends WatchUi.View {
    private var _stats = new SolarStats();
    private var _graph = [] as Array;
    private var _error as Boolean = false;
    private var _message = _na_ as String;
    private var _today = _na_ as String;
    private var _day = _na_ as String;
    private var _last6hours = _na_ as String;
    private var _month = _na_ as String;
    private var _year = _na_ as String;
    private var _consumed = _na_ as String;
    private var _current = _na_ as String;
    private var _showconsumption as Boolean = false;
    private var _errorMessage as WatchUi.TextArea;

    //! Constructor
    public function initialize() {
        WatchUi.View.initialize();
        //_showconsumption = Properties.getValue($.consumption);
    }

    //! Load your resources here
    //! @param dc Device context
    public function onLayout(dc as Dc) as Void {
        _today      = WatchUi.loadResource($.Rez.Strings.today) as String;
        _day        = WatchUi.loadResource($.Rez.Strings.day) as String;
        _month      = WatchUi.loadResource($.Rez.Strings.month) as String;
        _year       = WatchUi.loadResource($.Rez.Strings.year) as String;
        _consumed   = WatchUi.loadResource($.Rez.Strings.consumed) as String;
        _current    = WatchUi.loadResource($.Rez.Strings.current) as String;
        _last6hours = WatchUi.loadResource($.Rez.Strings.last6hours) as String;
    }

    //! Restore the state of the app and prepare the view to be shown
    public function onShow() as Void {
        _stats.generated = Storage.getValue("generated") as Float;
        _stats.consumed  = Storage.getValue("consumed") as Float;
        _stats.time      = Storage.getValue("time") as String;
    }

    //! Update the view
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if ( !_error ) {
            if ( _graph.size() == 0 ) {
                ShowValues(dc);
            } 
            else {
                switch ( GraphType(_graph[0].period) ) {
                case lineGraph:
                    ShowLineGraph(dc, _graph);
                    break;
                case barGraph:
                    ShowBarGraph(dc, _graph);
                    break;
                default:
                    break;
                }
            }
        } else {
            ShowError(dc);
        }
    }

    private function GraphType( period as String ) as GraphTypes {
        var gt = barGraph as GraphTypes;
        if ( period.equals("history") ) {
            gt = lineGraph;
        }
        return gt;
    }

    private function ShowValues(dc as Dc) {
        CheckValues();

        var fhLarge = dc.getFontHeight(Graphics.FONT_SYSTEM_LARGE);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);
        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        
        var locHeader = dc.getHeight() / 2 - 2*fhLarge - fhXTiny;
        var locGenerated = locHeader;
        var locGeneration = locHeader;
        var locConsumed = dc.getHeight() / 2 + 5;
        var locConsumption = locConsumed + fhTiny;
        var locTime = dc.getHeight() / 2 + 2*fhLarge;

        if ( _showconsumption ) {
            locGenerated = locGenerated + fhLarge;
            locGeneration = locGenerated + fhLarge;
        } else {
            locGenerated  = (dc.getHeight() - fhLarge) / 2;
            locGeneration = locGenerated + fhLarge + 5;
        }

        dc.drawText(dc.getWidth() / 2, locHeader, Graphics.FONT_LARGE, Header(_stats), Graphics.TEXT_JUSTIFY_CENTER );
        
        dc.drawText(dc.getWidth() / 2, locGenerated, Graphics.FONT_LARGE, (_stats.generated/1000).format("%.1f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, locGeneration, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.generating + " W", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, locTime, Graphics.FONT_SYSTEM_XTINY, "@ " + _stats.time, Graphics.TEXT_JUSTIFY_CENTER );

        if (_showconsumption ) {
            dc.drawText(dc.getWidth() / 2, locConsumed, Graphics.FONT_SYSTEM_TINY, _consumed + ": " + (_stats.consumed/1000).format("%.1f")+ " kWh", Graphics.TEXT_JUSTIFY_CENTER );
            dc.drawText(dc.getWidth() / 2, locConsumption, Graphics.FONT_SYSTEM_XTINY, _current + ": " + _stats.consuming + " W", Graphics.TEXT_JUSTIFY_CENTER );
        }
    }

    private function ShowLineGraph(dc as Dc, values as Array<SolarStats>) {
        // Find the max power/index in the array
        var maxIndex  = MaxGeneration(values);
        var maxPower = values[maxIndex].generating;
        if ( maxPower == null ) {
            maxPower = 0;
        }

        var width = dc.getWidth() as Long;
        var wideX = 0.80*width as Float;
        var wideY = 0.45*width as Float;
        var stepSize = (Math.round(wideX/values.size())).toLong();
        var offsetX = ((width / 2) + (stepSize*values.size()/2)).toLong();
        var offsetY = ((width / 2) + (wideY/2)).toLong();
        var height = wideY;

        // normalize power on y-axis
        var norm = Normalize(maxPower, height);

        dc.setAntiAlias(true);
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine (0, offsetY, width, offsetY);                       // x-axis
        dc.drawLine (offsetX, offsetY + 5, offsetX, offsetY - height);  // y-axis

        // draw 500W lines
        var yIdx = maxPower / 500;
        for ( var i = 1; i <= yIdx; i ++ ) {
            dc.drawLine( offsetX - 3, (offsetY - i*500/norm).toLong(), offsetX + 3, (offsetY - i*500/norm).toLong());
        }

        var fX = offsetX;
        var fY = offsetY - (CheckValue(values[0].generating) / norm).toLong();
        for ( var i = 1; i < values.size(); i++ ) {
            var tX = offsetX - stepSize*i;
            var tY = offsetY - (CheckValue(values[i].generating) / norm).toLong();
            
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_BLACK);
            dc.drawLine(fX, fY, tX, tY);

            if ( i == maxIndex ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY, offsetX - stepSize*i, offsetY - height);
            }

            if ( values[i].time.find(":00") != null ) {
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                dc.drawLine(offsetX - stepSize*i, offsetY + 5, offsetX - stepSize*i, offsetY - 5);
            }

            fX = tX;
            fY = tY;
        }

        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() + height) / 2 + 5, Graphics.FONT_SYSTEM_TINY, _last6hours, Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, (CheckValue(values[0].generated)/1000).format("%.1f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhXTiny - 5, Graphics.FONT_SYSTEM_XTINY, "Max: " + values[maxIndex].generating + " W @ " + values[maxIndex].time, Graphics.TEXT_JUSTIFY_CENTER );
    }

    private function ShowBarGraph(dc as Dc, values as Array<SolarStats>) {
        // First find the max index/value in the array
        var mig  = MaxGenerated(values);
        var mg = values[mig].generated;
        var mic = MaxConsumption(values);
        var mc = values[mig].consumed;

        var maxIndex = mig;
        var maxPower = mg;
        if ( _showconsumption and mc > mg ) {
            maxIndex = mic;
            maxPower = mc;
        }

        var width = dc.getWidth() as Long;
        var wideX = 0.80*width as Float;
        var wideY = 0.45*width as Float;
        var stepSize = (Math.round(wideX/values.size())).toLong();
        var offsetX = ((width / 2) + (stepSize*values.size()/2)).toLong();
        var offsetY = ((width / 2) + (wideY/2)).toLong();
        var height = wideY;

        // normalize power on y-axis
        var norm = Normalize(maxPower, height);

        // draw axis
        dc.setAntiAlias(true);
        dc.setPenWidth(2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine (0, offsetY, width, offsetY);                       // x-axis
        dc.drawLine (offsetX, offsetY + 5, offsetX, offsetY - height);  // y-axis

        var divider = 100000;               // draw 100kWh lines
        if ( maxPower < 50000 ) {
            divider = 5000;                 // draw 5kWh lines
        } else if ( maxPower > 1000000 ) {  
            divider = 500000;               // draw 500kWh lines
        }
        var yIdx = maxPower / divider;

        //draw vertical ticks
        for ( var i = 1; i <= yIdx; i ++ ) {
            dc.drawLine( offsetX - 3, (offsetY - i*divider/norm).toLong(), offsetX + 3, (offsetY - i*divider/norm).toLong());
        }

        var fhTiny  = dc.getFontHeight(Graphics.FONT_SYSTEM_TINY);
        var fhXTiny = dc.getFontHeight(Graphics.FONT_SYSTEM_XTINY);

        for ( var i = 0; i < values.size(); i++ ) {
            var x1 = offsetX - stepSize*(i+1) + 5;
            var x2 = x1 - 3;
            var w = stepSize - 10;
            var h1 = (CheckValue(values[i].generated) / norm).toLong();
            var h2 = (CheckValue(values[i].consumed) / norm).toLong();
            var y1 = offsetY - h1;
            var y2 = offsetY - h2;
            
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
            dc.fillRectangle(x1, y1, w, h1);
            if ( _showconsumption ) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
                dc.drawRectangle(x2, y2, w + 7, h2);
            }

            dc.setPenWidth(1);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawLine(offsetX - stepSize*i, offsetY + 5, offsetX - stepSize*i, offsetY - 5);

            if ( values.size() < 12 or (i % 2 == 0) ) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                var dateString = Date(values[i]);
                var textWidth = dc.getTextWidthInPixels(dateString, Graphics.FONT_SYSTEM_XTINY);
                if ( (textWidth+2) > stepSize and dateString.length() == 3 ) {
                    dateString = dateString.substring(0, 1);
                }
                dc.drawText(offsetX - stepSize*(i+0.5), offsetY, Graphics.FONT_SYSTEM_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER );
            }
        }


        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() + height) / 2 + fhXTiny, Graphics.FONT_SYSTEM_TINY, Header(values[0]), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhTiny - fhXTiny - 5, Graphics.FONT_SYSTEM_TINY, ((CheckValue(values[0].generated)/1000).toFloat()).format("%.0f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        if ( _showconsumption ) {
            dc.drawText(dc.getWidth() / 2, (dc.getHeight() - height) / 2 - fhXTiny - 5, Graphics.FONT_SYSTEM_XTINY, _consumed + ": " + ((CheckValue(values[0].consumed)/1000).toFloat()).format("%.0f") + " kWh", Graphics.TEXT_JUSTIFY_CENTER );
        }
    }

    private function Normalize( maximum as Long, height as Float ) as Float {
        var norm = maximum / height;

        if ( norm < 1.0 ) {
            norm = 1.0;
        }

        return norm;
    }

    private function Date( values as SolarStats ) as String {
        var dateString = values.date;
        if ( values.period.equals("week") ) {
            var dI = DateStringToInfo(values.date);
            dateString = dI.day_of_week.substring(0,1);
        }
        return dateString;
    }

    private function MaxGenerated( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( CheckValue(array[i].generated) > maxPower ) {
                maxPower = array[i].generated;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function MaxGeneration( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( CheckValue(array[i].generating) > maxPower ) {
                maxPower = array[i].generating;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function MaxConsumption( array as Array<SolarStats> ) as Number {
        var maxIndex = 0;
        var maxPower = 0;
        for ( var i = 0; i < array.size(); i++ ) {
            if ( CheckValue(array[i].generated) > maxPower ) {
                maxPower = array[i].generated;
                maxIndex = i;
            }
        }
        return maxIndex;
    }

    private function ShowError(dc as Dc) {
        _errorMessage = new WatchUi.TextArea({
            :text=>_message,
            :font=>[Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_XTINY],
            :locX =>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER,
            :width=>dc.getHeight()*0.66,
            :height=>dc.getWidth()*0.66
        });        
        _errorMessage.draw(dc);
    }

    private function CheckValue( value as Long ) as Long {
        if ( value == null ) {
            value = NaN;
        }
        return value;
    }

    private function Header( stats as SolarStats ) as String {
        var header = _na_;
        if ( stats.period.equals("day") ) {
            header = _today;
        } else if ( stats.period.equals("week") ) {
            header = _day;
        } else if ( stats.period.equals("month") ) {
            header = _month;
        } else if ( stats.period.equals("year") ) {
            header = _year;
        }
        return header;
    }

    private function CheckValues() {
        _stats.generated    = CheckValue(_stats.generated);
        _stats.consumed     = CheckValue(_stats.consumed);
        _stats.generating   = CheckValue(_stats.generating);
        _stats.consuming    = CheckValue(_stats.consuming);

        if ( _stats.time == null ) {
            _stats.time = "n/a";
        }
        if ( _stats.period == null ) {
            _stats.period = "n/a";
        }
    }

    private function DateStringToInfo(dateString as String ) as Gregorian.Info {
        return DateInfo(dateString.substring(0,4), dateString.substring(5,7), dateString.substring(8,10));
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

    //! Called when this View is removed from the screen. Save the
    //! state of your app here.
    public function onHide() as Void {
        Storage.setValue("generated", _stats.generated);
        Storage.setValue("consumed",  _stats.consumed);
        Storage.setValue("time",      _stats.time);
    }

    //! Show the result or status of the web request
    //! @param args Data from the web request, or error message
    public function onReceive(result as SolarStats or Array or String or Null) as Void {
        if (result instanceof String) {
            _error      = true;
            _message    = result;
            _graph      = [];
        } else if (result instanceof SolarStats ) {
            _error      = false;
            _stats      = result;
            _graph      = [];
        } else if (result instanceof Array ) {
            _error      = false;
            _graph      = result;
        }
        WatchUi.requestUpdate();
    }
}
