//
//  document.js
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


var duckduckgoDocument = function () {
    
    myAppGetHTMLElementsAtPoint = function(x, y) {
        var tags = "·";
        var e = document.elementFromPoint(x,y);
        while (e) {
            if (e.tagName == "IMG") {
                tags += "IMG" + "|" + e.src + '·';
                
                var filename;
                if(e.src.indexOf("/")>0)
                {
                    filename=e.src.substring(e.src.lastIndexOf("/")+1,e.src.length);
                }
                else
                {
                    filename=e.src;
                }
                tags += "IMGName" + "|" + filename + '·';
            }
            if (e.tagName == "A") {
                tags += "A" + "|" + e.href + '·';
                tags += "AName" + "|" + e.innerText + '·';
            }
            e = e.parentNode;
        }
        return tags
    };
    
    return {
    myAppGetHTMLElementsAtPoint: myAppGetHTMLElementsAtPoint
    };
    
}();
