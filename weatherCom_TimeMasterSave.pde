//##################################################
//#################Datei Managment##################
//##################################################
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

String datum = day() + "." + month() + "." + year(); 
String table = "Zeitpunkt;Temperatur;Luftfeuchtigkeit";
String rootPath = "G:/Dokumente/Processing/WetterStation/weatherCom_TimeMasterSave";
String[] Values = new String[2];//Definiert wie viele Daten gespeichert werden
//##################################################
//###############Zeit Implementierung###############
//##################################################
class Time{
   int s = 0;
   int m = 0;
   int h = 0;
   int d = 0;
}

Time endOfSchedule = new Time();
Time currentTime = new Time();
Time delay = new Time();

//##################################################
//###########Basis um den Sensor auszulsen##########
//##################################################
//Importiert die Bibliothek für die Serielle Kommunikation
import processing.serial.*;

//Legt ein neues Obejekt an, mit dem man eine Seriele Kommunikation herstellen kann.
Serial ComArdu;

int nl = 10;

//In dieses Objekt wird der Sensorwert mit der empfangen Zeit gespeicht
class SensorVal{
  Time Time = new Time();//Zeitpunkt an dem der Wert gespeichert wurde
  String Val;//Wert vom der Seriellen Kommunikation
  int ValC;//Konvertierter String aus der Seriellen Kommunikation
}

//Initialisiert Objekte für die Temperatur und Luftfeuchtigkeits Werte
SensorVal temp = new SensorVal();//Sensor Wert für die Temperatur
SensorVal hum = new SensorVal();//Sensor Wert für die Luftfeutigkeit

void setup(){
  size(200, 200);
  surface.setTitle("");
  ComArdu = new Serial(this, "COM6", 9600);
  
//##############Delay Konfiguration#############
   setTime(delay, 0, 0, 0, 5);
  toCurrentTime(currentTime);
  toCurrentTime(endOfSchedule);
  setDelay(delay, endOfSchedule);
//##############Layout Datei#############
  save(table, rootPath, "/test.csv");
}
void draw(){
  toCurrentTime(currentTime);//Aktualisiert Zeit bei jedem Durchlauf
  boolean valid = compareTime(currentTime, endOfSchedule);//Kuck ob das Auslesen ausgeführt werden muss
  
  if(valid == true)
  { //<>//
    getVal(ComArdu, "getTemp" + '\n', "t", ":", temp, true);
    getVal(ComArdu, "getHum" + '\n', "h", ":", hum, true);
    println("Temperatur: " + temp.ValC);
    println("Luftfeuchtigkeit: " + hum.ValC);
    String[] Vals = new String[] {stringTime(temp.Time, ':'), temp.Val, hum.Val}; 
    String Values = MergeArray(Vals);
    save(Values, rootPath, "/test.csv");
    toCurrentTime(currentTime);
    toCurrentTime(endOfSchedule);
    setDelay(delay, endOfSchedule);
  }
}


//##################################################
//###########Arduino ansprechen#####################
//##################################################

void getVal(Serial Com, String cmd, String prefix, String seperator, SensorVal Val, boolean debug){
  String[] rawVal = new String[2]; //<>//
  boolean attempt = false; //Versuch ist Standartmäßig nicht erfolgreich. Erst erfolgreich wenn ein Wert umkonvertiert und gespeichert wird.
  int attempts = 0;
  
  Com.write(cmd);//Sendet den vorher Definierten Befehl an den Seriellen Port
  if(debug == true){
    println("---Suche " + prefix + "----");
  }
  do
    {
      if(Com.available() > 0)
      {
          String ComBuffer = Com.readStringUntil('\n');
          println(ComBuffer);
          if(ComBuffer != null)
          {
            if(ComBuffer.startsWith(prefix))
            {
              if(debug == true)
              {
                  println("Der wert " + prefix + " wurde gefunden!");
                  
              }
              
              rawVal = ComBuffer.split(seperator);//Löscht den definierten Seperator und speichert die einzelnen Teile des Strings in ein Array
              
              Val.Val = rawVal[1].trim();//Val der Variablenname z.B temp. Zweites Val ist der Pfad vom Objekt Sensor Val
                                         //Löscht alle Lehr- und Steuerzeichen und speichert den Wert in das Objekt
              
              if(isNumeric(Val.Val) == true)//Wenn der Abgespeicherte Wert eine Nummer ist wird der Block ausgeführt.
              {
                toCurrentTime(Val.Time);//Speichert den aktuellen Zeitpunkt in das Objekt vom Sensor Wert
                
                Val.ValC = Integer.parseInt(Val.Val);//Konvertiert den String in ein Integer und speichert ihn an den Pfad: Vaiablenname.ValC
                                                     //Das "C" seteht für Converted/Konvertiert
                attempt = true;//Da der Wert erfolgreich abgespeichert wurde, ist der Versuch erfolgreich.
                               //attempt steht für Versuch und das true steht für erfolgreich.
              }
              else
              //Falls der gespeicherte Wert kein String ist und der Wunsch zur ausgabe der Aktionen wahr ist wird ausgegeben, dass ein Zahlenwert gefunden worden ist. 
              {
                if(debug == true){
                println("Kein Zahlenwert vorhanden!");
                }
              }
            }
            else
            //Ist der gewünschte Prefix nicht vorhanden wird drauf hingewiesen, dass in dem Durchgang kein Wert gefunden worden ist.
            {
              if(debug == true){
                println("Kein Wert wurde gefunden");
              }
            }
          }
      }
      else{//Falls keine Daten über den Seriellen Port übertragen wurde
        if(debug == true){
          println("Keine Daten übertragen!");
        }
      }
      
  
  
      attempts++;//Da der Versuch nicht erfolgreich war wird auf die Veruche Varibele 1 dazu addiert
      if(attempts >= 50){
      //Sollte nach 50 Versuchen nichts erfolgreich abgespeichert worden wird an den Arduino, ein weiterer Befehl gesendet
            Com.write(cmd);
            attempts = 0;
      }
      delay(100);//Es wird 100 Millisekunden gewartet
  }while(attempt == false);//Die Schleife wird solange ausgeführt der Versuch nicht erfolgreich war
}


public static boolean isNumeric(String str)
//Prüft ob ein String ein Numerischer Wert ist
{  
  try  
  {  
    int d = Integer.parseInt(str);  
  }  
  catch(NumberFormatException nfe)  
  {  
    return false;  
  }  
  return true;  
}

//#############################################################
//########################Zeit Funktionen######################
//#############################################################
void setDelay(Time delay, Time endPoint){
//Konvertiert beide Objekt in Sekunden
    
    int ergDelay = convertToS(delay);
    int ergEndPoint = convertToS(endPoint);
//Addiert diese miteinander
    int erg = ergDelay + ergEndPoint;
//Convertiert diese in ein Zeit Objekt
    convertToTime(erg, endPoint); 

}

int convertToS(Time time)
{
  //Rechnet die Zeit in Sekunden um
  int erg = time.s + (time.m * 60) + (time.h * 3600) + (time.d * 86400);
  return erg;
}
void convertToTime(int valInSeconds, Time time)
{
   //Rechnet die Sekunden Daten in das Time Objekt um
   time.d = valInSeconds / 60 / 60 / 24 % 365;
   time.h = valInSeconds / 60 / 60 % 24;
   time.m = valInSeconds / 60 % 60;
   time.s = valInSeconds % 60; //<>//
}

void setTime(Time timeObj, int d, int h, int m, int s ){
  //Dies setzt die Zeit des Zeit Objektes
  Time time = new Time();
  time.d = d;
  time.h = h;
  time.m = m;
  time.s = s;
  
  //Sorgt dafür das es zu keinem Zahlen überlauf kommt
  int newTime = convertToS(time);
  convertToTime(newTime , timeObj);
  
}
void toCurrentTime(Time timeObj){
  //Diese Funktion sorgt dafür das der Buffer auf "null" gesetzt wird
  //Also auf die Aktuelle Zeit gesetzt wird
  timeObj.s = second();
  timeObj.m = minute();
  timeObj.h = hour();
  //timeObj.d = day();
}

boolean compareTime(Time stTime, Time ndTime){
  //Vergleicht zwei Zeit Objekte
  
  //Konvertiert beide Zeit Objekt in ein Integer
  int timeinSecFirst = convertToS(stTime);
  int timeinSecSecond = convertToS(ndTime);
  
  //Vergleicht diese Integer
  if(timeinSecFirst >= timeinSecSecond){
    //Wenn der Erst größer oder gleich dem Zweiten ist gibt 
    //die Funktion ein true zurück
    return true;
  }
  else
  {
    return false;
  }
}

public static String stringTime(Time Var, char seperator){
  //Gibt Zeit als String zurück
  String compared = str(Var.d) + seperator + str(Var.h) + seperator + str(Var.m) + seperator + str(Var.s);
  return compared;
}
//#############################################################
//#####################In Datei schreiben######################
//#############################################################
public void save(String val, String path, String name) {
    PrintWriter pWriter = null;
    try {
        pWriter = new PrintWriter(new BufferedWriter(new FileWriter(path + name, true)), true);
        pWriter.println(val);
    } catch (IOException ioe) {
        ioe.printStackTrace();
    } finally {
        if (pWriter != null){
            //pWriter.flush();
            pWriter.close();
            println("Success");
        }
    }
}
String MergeArray(String[] Val)
{
  String mergedValues = "";
  for(int i=0; i < Val.length; i++)
  {
    
    if(i != 0)
    {
      mergedValues = mergedValues + ";" + Val[i];
    }
    else if(i == 0){
      mergedValues = Val[i];
    }
  }
  return mergedValues;
}
