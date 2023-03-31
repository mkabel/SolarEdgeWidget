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

import Toybox.Lang;

(:background)
class SolarStats {
    public var consumed = NaN as Float;
    public var generated = NaN as Float;
    public var generating = NaN as Float;
    public var consuming = NaN as Float;
    public var period = unknown as Statistics;
    public var date = _na_ as String;
    public var time = _na_ as String;

    public function set( valueString as String ) {
        var result = ParseString(";", valueString);

        //TODO: #2 Throw exception if size is not matching!?
        if ( result.size() == 7 ) {
            period     = CheckLong(result[0].toNumber());
            date       = result[1];
            time       = result[2];
            generated  = CheckFloat(result[3].toFloat());
            generating = CheckFloat(result[4].toFloat());
            consumed   = CheckFloat(result[5].toFloat());
            consuming  = CheckFloat(result[6].toFloat());
        }
    }


    public function toString() as String {
        var string = period.toString();
        string += ";" + date;
        string += ";" + time;
        string += ";" + CheckFloat(generated).toString();
        string += ";" + CheckFloat(generating).toString();
        string += ";" + CheckFloat(consumed).toString();
        string += ";" + CheckFloat(consuming).toString();

        return string;
    }
}