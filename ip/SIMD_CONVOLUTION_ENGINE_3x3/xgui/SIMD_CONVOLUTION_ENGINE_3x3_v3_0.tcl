# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "Column_Size" -parent ${Page_0}
  ipgui::add_param $IPINST -name "Row_Size" -parent ${Page_0}


}

proc update_PARAM_VALUE.Column_Size { PARAM_VALUE.Column_Size } {
	# Procedure called to update Column_Size when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Column_Size { PARAM_VALUE.Column_Size } {
	# Procedure called to validate Column_Size
	return true
}

proc update_PARAM_VALUE.Row_Size { PARAM_VALUE.Row_Size } {
	# Procedure called to update Row_Size when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.Row_Size { PARAM_VALUE.Row_Size } {
	# Procedure called to validate Row_Size
	return true
}


proc update_MODELPARAM_VALUE.Column_Size { MODELPARAM_VALUE.Column_Size PARAM_VALUE.Column_Size } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Column_Size}] ${MODELPARAM_VALUE.Column_Size}
}

proc update_MODELPARAM_VALUE.Row_Size { MODELPARAM_VALUE.Row_Size PARAM_VALUE.Row_Size } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.Row_Size}] ${MODELPARAM_VALUE.Row_Size}
}

