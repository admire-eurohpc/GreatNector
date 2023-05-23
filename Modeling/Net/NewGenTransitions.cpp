#include <sys/stat.h>
#include <cstdlib>

#define IO_end 0
#define IO_queue 1
#define IO_start 2
#define State_end 3
#define State_start 4

static double prvTime=0.0;
static unsigned int prvStateId=0;
const double step=1.0; // unit time for the aggregation
static double nextPoint=step;

//static std::ofstream out("/home/docker/data/queueHPCmodel_calibration/TimePlaces/timedPlace.trace", std::ios::app);
static std::ofstream out("/home/docker/data/queueHPCmodel4analysis_analysis/timedPlace.trace", std::ios::app);

// if(!out){
//   throw Exception("*****Error opening output file result.trace***\n\n");
// }

/* place encoding
 IOQueue_n1_app1_q01	0
 IOQueue_n1_app1_q11	1
 IOQueue_n1_app1_q21	2
 IOQueue_n1_app1_q31	3
 IOQueue_n1_app1_q41	4
 SystemProcesses_n1_app1	5
 StateRunning_n1_app1_mpi2	11
 StateRunning_n1_app1_other3	12
 IORunning_n1_app1_q01	14
 IORunning_n1_app1_q11	15
 IORunning_n1_app1_q21	16
 IORunning_n1_app1_q31	17
 IORunning_n1_app1_q41	18 
 */

vector <int> placesIndex{0,1,2,3,4,5,11,12,14,15,16,17,18};
map <int,double> measure {
  {0, 0.0},
  {1, 0.0},
  {2, 0.0},
  {3, 0.0},
  {4, 0.0},
  {5, 0.0},
  {11, 0.0},
  {12, 0.0},
  {14, 0.0},
  {15, 0.0},
  {16, 0.0},
  {17, 0.0},
  {18, 0.0},
};

//vector<string> name_file_new = {"IO_end","IO_queue","IO_start","State_end", "State_start"};
//vector<Table> class_files(5, Table());

double IO_queue_general(double *Value,
                        map <string,int>& NumTrans,
                        map <string,int>& NumPlaces,
                        const vector<string> & NameTrans,
                        const struct InfTr* Trans,
                        const int T,
                        const double& time,
                        double rateFromTimeTable) {

  // if you run the analysis then comment the follow 2 lines:
  //if (time==0.0)
  //  system("mkdir -p /home/docker/data/queueHPCmodel_calibration/TimePlaces");
  //
  
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[IO_queue].getConstantFromTimeTable(time, 0);
  // cout << "time:" << time << "rate:" << rate << endl;
  
  /****
   * Begin Computing interval time in the state
   ****/
  //updating  measure
  if (time!=0.0){
    measure[prvStateId]+=time-prvTime;
  }
  
  //printing measure
  if (time==nextPoint){
    out<<nextPoint;
    for (auto it=measure.begin(); it!=measure.end();++it){
      out << "\t" << it->second/step;
      it->second = 0;
    }
    out<<endl;
    out.flush();
    nextPoint+=step;
  }
  
  //updating prvStateId
  unsigned int i=0;
  for (;i<placesIndex.size()&&Value[placesIndex[i]]==0;++i);
    prvStateId=placesIndex[i];
  
  //updating prvTime
  prvTime=time;
  
  /****
   * End Computing interval time in the state
   ****/
  
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}


double IO_end_general(double *Value,
                      map <string,int>& NumTrans,
                      map <string,int>& NumPlaces,
                      const vector<string> & NameTrans,
                      const struct InfTr* Trans,
                      const int T,
                      const double& time,
                      double rateFromTimeTable) {
  
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[IO_end].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}


double State_start_mpi_general(double *Value,
                               map <string,int>& NumTrans,
                               map <string,int>& NumPlaces,
                               const vector<string> & NameTrans,
                               const struct InfTr* Trans,
                               const int T,
                               const double& time,
                               double rateFromTimeTable) {
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[State_start].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}

double State_start_other_general(double *Value,
                                 map <string,int>& NumTrans,
                                 map <string,int>& NumPlaces,
                                 const vector<string> & NameTrans,
                                 const struct InfTr* Trans,
                                 const int T,
                                 const double& time,
                                 double rateFromTimeTable) {
  
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[State_start].getConstantFromTimeTable(time, 1);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}

double State_end_mpi_general(double *Value,
                             map <string,int>& NumTrans,
                             map <string,int>& NumPlaces,
                             const vector<string> & NameTrans,
                             const struct InfTr* Trans,
                             const int T,
                             const double& time,
                             double rateFromTimeTable) {
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[State_end].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}

double State_end_other_general(double *Value,
                               map <string,int>& NumTrans,
                               map <string,int>& NumPlaces,
                               const vector<string> & NameTrans,
                               const struct InfTr* Trans,
                               const int T,
                               const double& time,
                               double rateFromTimeTable) {
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[State_end].getConstantFromTimeTable(time, 1);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}

double IO_start_general(double *Value,
                        map <string,int>& NumTrans,
                        map <string,int>& NumPlaces,
                        const vector<string> & NameTrans,
                        const struct InfTr* Trans,
                        const int T,
                        const double& time,
                        double rateFromTimeTable) {
  // cout << "Transition:" << NameTrans[T] << endl;
  // double rate = class_files[IO_start].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  double rate = rateFromTimeTable * intensity; 
  return (rate);
}



