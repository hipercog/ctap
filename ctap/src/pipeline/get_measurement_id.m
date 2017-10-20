function measurementIDArr = get_measurement_id(MC, Filt)
MeasSub = struct_filter(MC.measurement, Filt);
measurementIDArr = {MeasSub.casename};