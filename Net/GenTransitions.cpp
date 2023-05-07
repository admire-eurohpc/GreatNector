#define IO_end 0
#define IO_queue 1
#define IO_start 2
#define State_end 3
#define State_start 4

//vector<string> name_file_new = {"IO_end","IO_queue","IO_start","State_end", "State_start"};
//vector<Table> class_files(5, Table());

double IO_queue_general(double *Value,
                        map <string,int>& NumTrans,
                        map <string,int>& NumPlaces,
                        const vector<string> & NameTrans,
                        const struct InfTr* Trans,
                        const int T,
                        const double& time) {
  
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[IO_queue].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}


double IO_end_general(double *Value,
                      map <string,int>& NumTrans,
                      map <string,int>& NumPlaces,
                      const vector<string> & NameTrans,
                      const struct InfTr* Trans,
                      const int T,
                      const double& time) {
  
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[IO_end].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}


double State_start_mpi_general(double *Value,
                               map <string,int>& NumTrans,
                               map <string,int>& NumPlaces,
                               const vector<string> & NameTrans,
                               const struct InfTr* Trans,
                               const int T,
                               const double& time) {
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[State_start].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}

double State_start_other_general(double *Value,
                                 map <string,int>& NumTrans,
                                 map <string,int>& NumPlaces,
                                 const vector<string> & NameTrans,
                                 const struct InfTr* Trans,
                                 const int T,
                                 const double& time) {
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[State_start].getConstantFromTimeTable(time, 1);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}

double State_end_mpi_general(double *Value,
                             map <string,int>& NumTrans,
                             map <string,int>& NumPlaces,
                             const vector<string> & NameTrans,
                             const struct InfTr* Trans,
                             const int T,
                             const double& time) {
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[State_end].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}

double State_end_other_general(double *Value,
                               map <string,int>& NumTrans,
                               map <string,int>& NumPlaces,
                               const vector<string> & NameTrans,
                               const struct InfTr* Trans,
                               const int T,
                               const double& time) {
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[State_end].getConstantFromTimeTable(time, 1);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}

double IO_start_general(double *Value,
                        map <string,int>& NumTrans,
                        map <string,int>& NumPlaces,
                        const vector<string> & NameTrans,
                        const struct InfTr* Trans,
                        const int T,
                        const double& time) {
  // cout << "Transition:" << NameTrans[T] << endl;
  double rate = class_files[IO_start].getConstantFromTimeTable(time, 0);
  // cout << "rate:" << rate << endl;
  
  double intensity = 1;
  for (unsigned int k=0; k<Trans[T].InPlaces.size(); k++){ 
    intensity *= pow(Value[Trans[T].InPlaces[k].Id],Trans[T].InPlaces[k].Card);  
  } 
  rate = rate * intensity; 
  return (rate);
}



