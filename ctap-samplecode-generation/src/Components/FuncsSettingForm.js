import React, { useContext } from "react";

import TextField from '@material-ui/core/TextField';
import IconButton from '@material-ui/core/IconButton';
import RemoveIcon from '@material-ui/icons/Remove';
import AddIcon from '@material-ui/icons/Add';
import Autocomplete from '@material-ui/lab/Autocomplete';
import { v4 as uuidv4 } from 'uuid';


import { Context } from './ContextProvider'
import { CTAP_funcs } from '../data/CTAP_funcs'

const FuncsSettingForm = ({ indexm, funcsSettings, classes, mid }) => {
    const [inputStates, dispatch] = useContext(Context);
    const [value, setValue] = React.useState(null);

    const handleInputChange = (id, name, newV) => {
        const values = [...inputStates];
        let index = values.findIndex(x => x.id === mid);
        const newInputStates = values[index].funcsSettings.map(i => {
            if (id === i.fid) {
                i[name] = newV;
                i[name+'Check'] = false;
            }
            return i;
        })
        values[index].funcsSettings = newInputStates;
        dispatch({ type: 'UPDATE_STEPSETS', data: values })
    }

    const handleAddFuncFields = () =>{
        const values = [...inputStates];
        let index = values.findIndex(x => x.id === mid);
        values[index].funcsSettings.push({ fid: uuidv4(), funcName: '', functionP: '' });
        dispatch({ type: 'UPDATE_STEPSETS', data: values })
    }

    const handleRemoveFuncFields = (id) =>{
        const values = [...inputStates];
        let index = values.findIndex(x => x.id === mid);
        let indexf = values[index].funcsSettings.findIndex(x => x.fid === id);
        values[index].funcsSettings.splice(indexf, 1);
        dispatch({ type: 'UPDATE_STEPSETS', data: values })
    }

    return (
        <form className={classes.root}>
            {funcsSettings.map((funcsSetting, index) => (
                <div key={funcsSetting.fid}>
                    <Autocomplete
                        id={'funcName'+index}
                        value = {inputStates[indexm].funcsSettings[index].funcName}
                        onChange={(event, newValue) => {
                            setValue(newValue);
                            handleInputChange(funcsSetting.fid, 'funcName', newValue);
                        }}
                        id="controllable-states-demo"
                        options={CTAP_funcs}
                        renderInput={(params) => <TextField {...params} error={funcsSetting.funcNameCheck} label="Function Name" variant="outlined" helperText={funcsSetting.funcNameCheck ? 'The field cannot be empty. Please select a function' : ''} />}
                    />
                    <TextField
                        id = {"funcP"+index}
                        name="funcP"
                        label="Function Parameters"
                        variant="filled"
                        value = {inputStates[indexm].funcsSettings[index].funcP}
                        helperText="check docs for parameters supported for each func, input in 'pName', p, eg.('method', 'fastica', 'overwrite', true). All the string input need single-quote:'input' "
                        onChange={event => handleInputChange(funcsSetting.fid, event.target.name, event.target.value)}
                    />
                    <IconButton disabled={funcsSettings.length === 1} onClick={() => handleRemoveFuncFields(funcsSetting.fid)}>
                        <RemoveIcon />
                    </IconButton>
                    <IconButton onClick={() => handleAddFuncFields()}>
                        <AddIcon />
                    </IconButton>
                </div>
            ))}
        </form>

    );
}

export default FuncsSettingForm;