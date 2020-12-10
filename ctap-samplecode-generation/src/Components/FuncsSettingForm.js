import React, { useContext, useEffect, useState } from "react";

import TextField from '@material-ui/core/TextField';
import IconButton from '@material-ui/core/IconButton';
import RemoveIcon from '@material-ui/icons/Remove';
import AddIcon from '@material-ui/icons/Add';
import Autocomplete from '@material-ui/lab/Autocomplete';
import Tooltip from '@material-ui/core/Tooltip';
import Typography from "@material-ui/core/Typography";
import { v4 as uuidv4 } from 'uuid';


import { ContextBranch, ContextLinear } from './ContextProvider'
import { CTAP_funcs } from '../data/CTAP_funcs'

const FuncsSettingForm = ({ ifLinear, index, indexm, funcsSettings, classes, mid }) => {

    const [inputBranchStates, dispatchB] = useContext(ContextBranch);
    const [inputLinearStates, dispatchL] = useContext(ContextLinear);
    const [value, setValue] = React.useState(null);
    const [inputStates, setInputStates] = useState(() => {
        if (ifLinear) {
            return inputLinearStates;
        } else {
            return inputBranchStates[index].linearSetting;
        }
    });

    useEffect(() => {
        if (ifLinear) {
            setInputStates(inputLinearStates);
        } else {
            setInputStates(inputBranchStates[index].linearSetting);
        }
    }, [inputLinearStates, inputBranchStates])

    const handleInputChange = (id, name, newV) => {
        const values = [...inputStates];
        let index_ = values.findIndex(x => x.id === mid);
        const newInputStates = values[index_].funcsSettings.map(i => {
            if (id === i.fid) {
                i[name] = newV;
                i[name + 'Check'] = false;
            }
            return i;
        })
        values[index_].funcsSettings = newInputStates;
        if (ifLinear) {
            dispatchL({ type: 'UPDATE_STEPSETS', data: values })
        } else {
            let newState = [...inputBranchStates];
            newState[index].linearSetting = values;
            dispatchB({ type: 'UPDATE_STEPSETS', data: newState })
        }

    }

    const handleAddFuncFields = () => {
        const values = [...inputStates];
        let index_ = values.findIndex(x => x.id === mid);
        values[index_].funcsSettings.push({ fid: uuidv4(), funcName: '', functionP: '' });
        if (ifLinear) {
            dispatchL({ type: 'UPDATE_STEPSETS', data: values })
        } else {
            let newState = [...inputBranchStates];
            newState[index].linearSetting = values;
            dispatchB({ type: 'UPDATE_STEPSETS', data: newState });
        }

    }

    const handleRemoveFuncFields = (id) => {
        const values = [...inputStates];
        let index_ = values.findIndex(x => x.id === mid);
        let indexf = values[index_].funcsSettings.findIndex(x => x.fid === id);
        values[index_].funcsSettings.splice(indexf, 1);
        if (ifLinear) {
            dispatchL({ type: 'UPDATE_STEPSETS', data: values });
        } else {
            let newState = [...inputBranchStates];
            newState[index].linearSetting = values;
            dispatchB({ type: 'UPDATE_STEPSETS', data: newState });
        }

    }


    return (
        <div className={classes.root}>
            {funcsSettings.map((funcsSetting, indexff) => (
                <div key={funcsSetting.fid}>
                    <Autocomplete
                        id={'funcName' + indexff}
                        value={inputStates[indexm].funcsSettings[indexff].funcName}
                        onChange={(event, newValue) => {
                            setValue(newValue);
                            handleInputChange(funcsSetting.fid, 'funcName', newValue);
                        }}
                        id="controllable-states-demo"
                        options={CTAP_funcs}
                        renderInput={(params) => <TextField {...params} error={funcsSetting.funcNameCheck} label="Function Name" variant="outlined" helperText={funcsSetting.funcNameCheck ? 'The field cannot be empty. Please select a function' : ''} />}
                    />
                    <Tooltip title={<Typography variant='body2'>{"check docs for parameters supported for each func, input in 'pName', p, eg.('method', 'fastica', 'overwrite', true). All the string input need single-quote:'input' "}</Typography>} classes={{ tooltip: classes.customWidth }}>
                        <TextField
                            id={"funcP" + indexff}
                            name="funcP"
                            label="Function Parameters"
                            variant="filled"
                            value={inputStates[indexm].funcsSettings[indexff].funcP}
                            onChange={event => handleInputChange(funcsSetting.fid, event.target.name, event.target.value)}
                        />
                    </Tooltip>

                    <IconButton disabled={funcsSettings.length === 1} onClick={() => handleRemoveFuncFields(funcsSetting.fid)}>
                        <RemoveIcon />
                    </IconButton>
                    <IconButton onClick={() => handleAddFuncFields()}>
                        <AddIcon />
                    </IconButton>
                </div>
            ))}
        </div>

    );
}

export default FuncsSettingForm;