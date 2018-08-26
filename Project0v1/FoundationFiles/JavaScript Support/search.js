//By Praveen P
//source from http://makeshortwork.blogspot.in/2017/02/javascript-search-highlight-next-previous-functionality-for-mobile-web-UIWebView-Code.html accessed Apr. 21, 2018

var totalsearchResultsFoundCount = 0;
var currentCount = -1;
var defaultSelectionColor = "#87CEFA";
var selectedSelectionColor = "#FFDEAD";
var keyNameHighlight = "IdhighlightMe";
var NxtHitCount = -1;

var nxtPrvColor = "red";
var arraySequenceId = 0;
var objSearchItems =  {};

function setStatusTextForMe(){
    var sts = document.getElementById("statusText");
    if(totalsearchResultsFoundCount>0)
        sts.innerHTML = (arraySequenceId+1)+ " of "+totalsearchResultsFoundCount;
    else sts.innerHTML = "";
}

function SetSequencingForMe(){
    
    var x = document.getElementsByClassName(keyNameHighlight);
    for(var i = 0; i < x.length; i++){
        for(var seq = 0; seq < objSearchItems.length; seq++){
            if(objSearchItems[seq].id == x[i].id){
                objSearchItems[seq].ActualSequenceNumber = i;
                console.log(objSearchItems[seq].id + " " + x[i].id + " updated "+ objSearchItems[seq].ActualSequenceNumber);
            }
        }
    }
}

function GetIdAndHighlightForMe(){
    var span = document.getElementById(keyNameHighlight+"0");
    var culprit = document.getElementById(keyNameHighlight+"0");
    for(var seq = 0; seq < objSearchItems.length; seq++){
        span = document.getElementById(objSearchItems[seq].id);
        if(objSearchItems[seq].ActualSequenceNumber == arraySequenceId)
        {
            span.style.backgroundColor = nxtPrvColor;
            culprit = span;
        }
        else{
            span.style.backgroundColor = defaultSelectionColor;
        }
    }
    return culprit;
}

function PrvForMe() {
    
    if(arraySequenceId <= 0){
        arraySequenceId = (totalsearchResultsFoundCount-1);
    }
    else if (arraySequenceId > 0) {
        --arraySequenceId;
    }
    var span = GetIdAndHighlightForMe();
    var visible = isItTrueElementInViewport(span);
    if (!visible){
        var spanTop = getElementTop(span);
        var spanLeft = span.offsetLeft;
        return spanTop + "," + spanLeft + "," + (arraySequenceId + 1) + "," + totalsearchResultsFoundCount;
    }
    else{
        return "0" + "," + "0" + "," + (arraySequenceId + 1) + "," + totalsearchResultsFoundCount;
    }
    //setStatusTextForMe();
    //scrollView();
}

function NxtForMe(){
    if(arraySequenceId < (totalsearchResultsFoundCount-1)){
        ++arraySequenceId ;
    }
    else if(arraySequenceId >= (totalsearchResultsFoundCount-1)){
        arraySequenceId = 0;
    }
    var span = GetIdAndHighlightForMe();
    var visible = isItTrueElementInViewport(span);
    if (!visible){
        var spanTop = getElementTop(span);
        var spanLeft = span.offsetLeft;
        return spanTop + "," + spanLeft + "," + (arraySequenceId + 1) + "," + totalsearchResultsFoundCount;
    }
    else{
        return "0" + "," + "0" + "," + (arraySequenceId + 1) + "," + totalsearchResultsFoundCount;
    }
    //setStatusTextForMe();
    //scrollView();
}

// helper function, recursively searches in elements and their child nodes
function GetAllOccurencesOfTextForElement(element,keyword) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                
                var idx = value.toLowerCase().indexOf(keyword);
                if (idx < 0) break;             // not found, abort
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx,keyword.length));
                span.appendChild(text);
                var str1 = keyNameHighlight+totalsearchResultsFoundCount;
                span.setAttribute("class", keyNameHighlight);
                span.setAttribute("id", str1);
                span.style.backgroundColor = defaultSelectionColor;
                span.style.color = "black";
                text = document.createTextNode(value.substr(idx+keyword.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
                if (span.offsetTop != 0 || span.offsetLeft != 0){
                totalsearchResultsFoundCount++;  // update the counter
                
                objSearchItems.push({id:str1,IsSelected:false,searchResultSerial:totalsearchResultsFoundCount,ActualSequenceNumber:-1});
                } else {
                    span.setAttribute("class", "abortedlol");
                }
                //console.log(objSearchItems);
            }
        } else if (element.nodeType == 1) { // // Element node - Element, Text, Comment, ProcessingInstruction, CDATASection, EntityReference
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
                
                for (var currentElement = element.childNodes.length-1; currentElement >= 0; currentElement--) {
                    GetAllOccurencesOfTextForElement(element.childNodes[currentElement],keyword);
                }
            }
        }
    }
}

function GetAllOccurencesOfText(keyword) {
    
    removeExistingHighlights();
    
    //keyword = document.getElementById('txt').value ;
    
    objSearchItems = new Array();
    
    GetAllOccurencesOfTextForElement(document.body, keyword.toLowerCase());
    
    SetSequencingForMe();
    
    GetIdAndHighlightForMe();
    
    //setStatusTextForMe();
    
}

// helper function, recursively removes the highlights in elements and their childs
function removeExistingHighlightsForElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            if (element.getAttribute("class") == keyNameHighlight) {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text,element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var currentElement = element.childNodes.length-1; currentElement >= 0; currentElement--) {
                    if (removeExistingHighlightsForElement(element.childNodes[currentElement])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

// the main entry point to remove the highlights
function removeExistingHighlights() {
    totalsearchResultsFoundCount = 0;
    currentCount = -1;
    arraySequenceId = 0;
    removeExistingHighlightsForElement(document.body);
}

function isItTrueElementInViewport(el) {
    var rect = el.getBoundingClientRect();
    return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) && /*or $(window).height() */
            rect.right <= (window.innerWidth || document.documentElement.clientWidth) /*or $(window).width() */
            );
}

function getElementTop(elem){
    
    var elemTop=elem.offsetTop;//获得elem元素距相对定位的父元素的top
    var elemm = elem;
    elem=elem.offsetParent;//将elem换成起相对定位的父元素
    
    
    while(elem!=null){//只要还有相对定位的父元素
        
        
        /*获得父元素 距他父元素的top值,累加到结果中 */
        
        
        elemTop+=elem.offsetTop;
        
        
        //再次将elem换成他相对定位的父元素上;
        
        
        elem=elem.offsetParent;
    }
    if (elemm.offsetTop != elemTop){
        elemm.scrollIntoView();
    }
    return elemTop;
}

