import React, { useState} from "react";
import TextField from '@material-ui/core/TextField';
import Button from '@material-ui/core/Button';
import IconButton from '@material-ui/core/IconButton';
import RemoveIcon from '@material-ui/icons/Remove';
import AddIcon from '@material-ui/icons/Add';
import Icon from '@material-ui/core/Icon';
import Select from '@material-ui/core/Select';
import Autocomplete from '@material-ui/lab/Autocomplete';

import FuncsSettingForm from "./FuncsSettingForm"


import { makeStyles } from '@material-ui/core/styles';

const useStyles = makeStyles((theme) => ({
    root: {
        '& .MuiTextField-root': {
            margin: theme.spacing(1),
            width: '50ch'
        },

    },
    button: {
        margin: theme.spacing(1),
    }

}))

const LinearPipesForm = ({ inputFields, handleFuncsSettingInput, handleLinearPipesInput, handleRemoveFuncFields, handleAddFuncFields, handleSubmit }) => {
    const classes = useStyles()

    return (
        <form className={classes.root} onSubmit={handleSubmit}>
            {inputFields.map((inputField, index) => (
                <div key={inputField.id}>
                    <h4>stepSet {index + 1}</h4>
                    <TextField
                        name="stepID"
                        label="stepID"
                        variant="filled"
                        helperText="describe main work in this stepSet, eg.'_load'"
                        value={inputField.stepID}
                        onChange={event => handleLinearPipesInput(inputField.id, event)}
                    />

                    {/* <FuncsSettingForm
                            classes={classes}
                            mid={inputField.id}
                            funcsSettings={inputField.funcsSettings}
                            handleAddFuncFields={handleAddFuncFields}
                            handleRemoveFuncFields={handleRemoveFuncFields}
                            handleFuncsSettingInput={handleFuncsSettingInput} /> */}
                    <form className={classes.root}>
                        {inputField.funcsSettings.map((funcsSetting, index) => (
                            <div key={funcsSetting.fid}>
                                <TextField
                                    autoFocus
                                    name="functionName"
                                    label="Function Name"
                                    variant="filled"
                                    defaultValue={funcsSetting.functionName}
                                    onChange={event => handleFuncsSettingInput(inputField.id, funcsSetting.fid, event)}
                                />
                                <TextField
                                    name="functionP"
                                    label="Function Parameters"
                                    variant="filled"
                                    helperText="check docs for parameters supported for each func, input in 'pName', p, eg.('method', 'fastica', 'overwrite', true). All the string input need single-quote:'input' "
                                    defaultValue={funcsSetting.functionP}
                                    onChange={event => handleFuncsSettingInput(inputField.id, funcsSetting.fid, event)}
                                />
                                <IconButton disabled={inputField.funcsSettings.length === 1} onClick={() => handleRemoveFuncFields(inputField.id, funcsSetting.fid)}>
                                    <RemoveIcon />
                                </IconButton>
                                <IconButton onClick={() => handleAddFuncFields(inputField.id)}>
                                    <AddIcon />
                                </IconButton>
                            </div>
                        ))}
                    </form>

                </div>
            ))}
            <Button
                className={classes.button}
                variant="contained"
                color="primary"
                type="submit"
                onClick={handleSubmit}
            >Send</Button>
        </form>

    );
}

export default LinearPipesForm;