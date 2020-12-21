// decided to split this off into its own file because theres no way in hell im gonna let all these sit in the main shader files
// post effect controllers
float gammaUp    : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Gamma+";     >;
float gammaDown  : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Gamma-";     >;
float saturation : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Saturation"; >;
float glowUp     : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow+";      >;
float glowDown   : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-";      >;
// main character controllers
// specular will control the rim color also
float specularRup   : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularR+"; >;
float specularGup   : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularG+"; >;
float specularBup   : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularB+"; >;
float specularAup   : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularA+"; >;
float specularRdown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularR-"; >;
float specularGdown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularG-"; >;
float specularBdown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularB-"; >;
float specularAdown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "SpecularA-"; >;