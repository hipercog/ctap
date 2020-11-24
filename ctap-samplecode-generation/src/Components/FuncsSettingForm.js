import TextField from '@material-ui/core/TextField';
import Button from '@material-ui/core/Button';
import IconButton from '@material-ui/core/IconButton';
import RemoveIcon from '@material-ui/icons/Remove';
import AddIcon from '@material-ui/icons/Add';
import Icon from '@material-ui/core/Icon';
import Select from '@material-ui/core/Select';


const FuncsSettingForm = ({ classes, mid, funcsSettings, handleFuncsSettingInput, handleRemoveFuncFields, handleAddFuncFields}) => {
    console.log(funcsSettings);
    return (
        <form className={classes.root}>
            {funcsSettings.map((funcsSetting, index) => (
                <div key={funcsSetting.fid}>
                    <TextField
                        autoFocus
                        name="functionName"
                        label="Function Name"
                        variant="filled"
                        defaultValue={funcsSetting.functionName}
                        onChange={event => handleFuncsSettingInput(mid, funcsSetting.fid, event)}
                    />
                    <TextField
                        name="lastfunctionPName"
                        label="Function Parameters"
                        variant="filled"
                        defaultValue={funcsSetting.functionP}
                        onChange={event => handleFuncsSettingInput(mid, funcsSetting.fid, event)}
                    />
                    <IconButton disabled={funcsSettings.length === 1} onClick={() => handleRemoveFuncFields(mid, funcsSetting.fid)}>
                        <RemoveIcon />
                    </IconButton>
                    <IconButton onClick={() => handleAddFuncFields(mid)}>
                        <AddIcon />
                    </IconButton>
                </div>
            ))}
        </form>

    );
}

export default FuncsSettingForm;